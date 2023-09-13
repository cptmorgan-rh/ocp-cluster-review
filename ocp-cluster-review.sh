#!/bin/bash

run() {

  case "$1" in
    --all)
      all
      ;;
    --auth)
      auth
      ;;
    --etcd)
      etcd
      ;;
    --kubeapi)
      kube-api
      ;;
    --scheduler)
      scheduler
      ;;
    --dns)
      dns
      ;;
    --ingress)
      ingress
      ;;
    --sdn)
      sdn
      ;;
    --kubecontrol)
      kube_controller
      ;;
    --podnetcheck)
      podnetcheck
      ;;
    --help)
      show_help
      ;;
    *)
      show_help
      exit 0
  esac

}

show_help(){

cat  << ENDHELP
USAGE: $(basename "$0")
ocp-cluster-review is a simple script which searches the logs of an OpenShift Cluster
for known issues and reports the namespace, pod, and the count for the errors found.

Options:
  --all          Performs all options
  --etcd         Searches for known errors in the eoptions
  --kubeapi      Searches for known errors in the kube-apiserveoptions
  --scheduler    Searches for known errors in the openshift-kube-scheduler-* pods
  --dns          Searches for known errors in dns-default-* pods
  --ingress      Searches for known errors in router-default-* pods
  --sdn          Searches for known errors in sdn-* pods
  --kubecontrol  Searches for known errors in kube-controller-manager-* pods
  --auth         Searches for known errors in oauth-openshift-* pods
  --help         Shows this help message

ENDHELP

}

dep_check(){

if [ ! $(command -v jq) ]; then
  echo "jq not found. Please install jq."
  exit 1
fi

}

all(){

  etcd

  kube-api

  scheduler

  dns

  ingress

  sdn

  auth

  kube_controller

}

etcd(){

#Check to make sure the openshift-etcd namespace exits
if [ ! "$(oc get ns openshift-etcd 2>/dev/null)" ]; then
  echo -e "openshift-etcd not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-etcd -l app=etcd --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No etcd Pods in Running State\n"
  return 1
else
  # set etcd pods
  etcd_pods=$(oc get pods -l app=etcd -n openshift-etcd --no-headers | awk '{ print $1 }')
fi

# set column names
etcd_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# etcd pod errors
etcd_etcd_errors_arr=("waiting for ReadIndex response took too long, retrying" "etcdserver: request timed out" "slow fdatasync" "\"apply request took too long\"" "\"leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk\"" "local no
de might have slow network" "elected leader" "lost leader" "wal: sync duration" "the clock difference against peer" "lease not found" "rafthttp: failed to read" "server is likely overloaded" "lost the tcp streaming" "sending buffer is full" "health errors")

for i in $etcd_pods; do
  oc logs pod/"$i" -n openshift-etcd -c etcd > $i
  for val in "${etcd_etcd_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     etcd_output_arr+=("openshift-etcd|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#etcd_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${etcd_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset etcd_output_arr

for i in $etcd_pods; do
    max=0
    min=9999
    avg=0
    count=0
    if grep 'took too long.*expec' "$i" > /dev/null 2>&1;
    then

      expected=$(grep -m1 'took too long.*expec' "$i" | grep -o "\{.*\}" | jq -r '."expected-duration"' 2>/dev/null)
      first=$(grep -m1 'took too long.*expec' "$i" 2>/dev/null | grep -o "\{.*\}" | jq -r '.ts')
      last=$(grep 'took too long.*expec' "$i" 2>/dev/null | tail -n1 | grep -o "\{.*\}" | jq -r '.ts')

      for x in $(grep 'took too long.*expec' "$i" | grep -Ev 'leader|waiting for ReadIndex response took too long' | grep -o "\{.*\}"  | jq -r '.took' 2>/dev/null | grep -Ev 'T|Z' 2>/dev/null); do
        if [[ $x =~ [1-9]m[0-9] ]];
        then
          compact_min=$(echo "scale=2;$(echo $x | grep -Eo '[1-9]m' | sed 's/m//')*60000" | bc)
          compact_sec=$(echo "scale=2;$(echo $x | sed -E 's/[1-9]+m//' | grep -Eo '[1-9]?\.[0-9]+')*1000" | bc)
          compact_time=$(echo "scale=2;$compact_min + $compact_sec" | bc)
        elif [[ $x =~ [1-9]s ]];
        then
          compact_time=$(echo "scale=2;$(echo $x | sed 's/s//')*1000" | bc)
        else
          compact_time=$(echo $x | sed 's/ms//')
        fi
        if [[ $(echo "$compact_time > $max" | bc -l 2>/dev/null) -eq 1 ]];
        then
          max=$(echo $compact_time | sed -e 's/[0]*$//g')
        fi
        if [[ $(echo "$compact_time > $min" | bc -l 2>/dev/null) -eq 0 ]];
        then
          min=$(echo $compact_time | sed -e 's/[0]*$//g')
        fi
        count=$(( $count + 1 ))
        avg=$(echo "$avg + $compact_time" | bc )
      done
      printf "Stats about etcd 'took long' messages: $(echo "$i" | awk -F/ '{ print $4 }')\n"
      printf "\tFirst Occurance: ${first}\n"
      printf "\tLast Occurance: ${last}\n"
      printf "\tMax: ${max}ms\n"
      printf "\tMin: ${min}ms\n"
      printf "\tAvg: $(echo "$avg/$count" | bc)ms\n"
      printf "\tExpected: ${expected}\n"
      printf "\n"
    fi
done

for i in $etcd_pods; do
    max=0
    min=9999
    avg=0
    count=0
    if grep -m1 "finished scheduled compaction" "$i" | grep '"took"'  > /dev/null 2>&1;
    then
      for x in $(grep "finished scheduled compaction" "$i" | jq -r '.took'); do
        if [[ $x =~ [1-9]m[0-9] ]];
        then
          compact_min=$(echo "scale=2;$(echo $x | grep -Eo '[1-9]m' | sed 's/m//')*60000" | bc)
          compact_sec=$(echo "scale=2;$(echo $x | sed -E 's/[1-9]+m//' | grep -Eo '[1-9]?\.[0-9]+')*1000" | bc)
          compact_time=$(echo "scale=2;$compact_min + $compact_sec" | bc)
        elif [[ $x =~ [1-9]s ]];
        then
          compact_time=$(echo "scale=2;$(echo $x | sed 's/s//')*1000" | bc)
        else
          compact_time=$(echo $x | sed 's/ms//')
        fi
        if [[ $(echo "$compact_time > $max" | bc -l) -eq 1 ]];
        then
          max=$(echo $compact_time | sed -e 's/[0]*$//g')
        fi
        if [[ $(echo "$compact_time > $min" | bc -l) -eq 0 ]];
        then
          min=$(echo $compact_time | sed -e 's/[0]*$//g')
        fi
        count=$(( $count + 1 ))
        avg=$(echo "$avg + $compact_time" | bc )
      done
      printf "etcd DB Compaction times: $(echo "$i")\n"
      printf "\tMax: ${max}ms\n"
      printf "\tMin: ${min}ms\n"
      printf "\tAvg: $(echo "$avg/$count" | bc)ms\n"
      printf "\n"
    fi
done

# clean up logs
for i in $etcd_pods; do
  rm "$i"
done

}

kube-api(){

#Check to make sure the openshift-kube-apiserver namespace exits
if [ ! "$(oc get ns openshift-kube-apiserver 2>/dev/null)" ]; then
  echo -e "openshift-kube-apiserver not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No etcd Pods in Running State\n"
  return 1
else
  # Set kube-api pods
  kube_api_pods=$(oc get pods -n openshift-kube-apiserver -l app=openshift-kube-apiserver --no-headers | awk '{ print $1 }')
fi

# set column names
kubeapi_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# kube-apiserver pod errors
kubeapi_errors_arr=("timeout or abort while handling")

for i in $kube_api_pods; do
  oc logs pod/"$i" -n openshift-kube-apiserver > $i
  for val in "${kubeapi_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     kubeapi_output_arr+=("$(echo "openshift-kube-apiserver")|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#kubeapi_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${kubeapi_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset kubeapi_output_arr

# clean up logs
for i in $kube_api_pods; do
  rm "$i"
done

}

scheduler(){

#Check to make sure the openshift-kube-scheduler namespace exits
if [ ! "$(oc get ns openshift-kube-scheduler 2>/dev/null)" ]; then
  echo -e "openshift-kube-scheduler not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-kube-scheduler -l app=openshift-kube-scheduler --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No etcd Pods in Running State\n"
  return 1
else
  # Set kube-api pods
  scheduler_pods=$(oc get pods -n openshift-kube-scheduler -l app=openshift-kube-scheduler --no-headers | awk '{ print $1 }')
fi

# set column names
scheduler_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# kube-scheduler pod errors
scheduler_errors_arr=("net/http: request canceled (Client.Timeout exceeded while awaiting headers)" "6443: connect: connection refused" "Failed to update lock: etcdserver: request timed out")

for i in $scheduler_pods; do
  oc logs pod/"$i" -n openshift-kube-scheduler > $i
  for val in "${scheduler_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     scheduler_output_arr+=("$(echo "openshift-kube-scheduler")|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#scheduler_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${scheduler_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset scheduler_output_arr

# clean up logs
for i in $scheduler_pods; do
  rm "$i"
done

}

dns(){

#Check to make sure the openshift-dns namespace exits
if [ ! "$(oc get ns openshift-dns 2>/dev/null)" ]; then
  echo -e "openshift-dns not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No etcd Pods in Running State\n"
  return 1
else
  # Set dns pods
  dns_pods=$(oc get pods -n openshift-dns -l dns.operator.openshift.io/daemonset-dns=default --no-headers | awk '{ print $1 }')
fi

# set column names
dns_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# dns pod errors
dns_errors_arr=("TLS handshake timeout" "i/o timeout" "connection reset by peer" "client connection lost" "no route to host" "connection refused")

for i in $dns_pods; do
  oc logs pod/"$i" -n openshift-dns -c dns > $i
  for val in "${dns_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     dns_output_arr+=("$(echo "openshift-dns") |$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#dns_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${dns_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset dns_output_arr

# clean up logs
for i in $dns_pods; do
  rm "$i"
done

}

ingress(){

#Check to make sure the openshift-ingress namespace exits
if [ ! "$(oc get ns openshift-ingress 2>/dev/null)" ]; then
  echo -e "openshift-ingress not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No etcd Pods in Running State\n"
  return 1
else
  # Set ingress pods
  ingress_pods=$(oc get pods -n openshift-ingress -l ingresscontroller.operator.openshift.io/deployment-ingresscontroller=default --no-headers | awk '{ print $1 }')
fi

# set column names
ingress_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# router pod errors
ingress_errors_arr=("unable to find service" "error reloading router: exit status 1" "connection refused" "Failed to make webhook authenticator request")

for i in $ingress_pods; do
  oc logs pod/"$i" -n openshift-ingress -c router > $i
  for val in "${ingress_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     ingress_output_arr+=("$(echo "openshift-ingress")|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#ingress_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${ingress_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset ingress_output_arr

# clean up logs
for i in $ingress_pods; do
  rm "$i"
done

}

sdn(){

#Check to make sure the openshift-sdn namespace exits
if [ ! "$(oc get ns openshift-sdn 2>/dev/null)" ]; then
  echo -e "openshift-sdn not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods-n openshift-sdn -l app=sdn --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No etcd Pods in Running State\n"
  return 1
else
  # Set sdn pods
  sdn_pods=$(oc get pods -n openshift-sdn -l app=sdn --no-headers | awk '{ print $1 }')
fi

# set column names
sdn_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# sdn pod errors
sdn_errors_arr=("connection refused" "an error on the server (\"\") has prevented the request from succeeding" "Failed to get local addresses during proxy sync" "the server has received too many requests and has asked us to try again later")

for i in $sdn_pods; do
  oc logs pod/"$i" -n openshift-sdn -c sdn > $i
  for val in "${sdn_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     sdn_output_arr+=("$(echo "openshift-sdn")|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#sdn_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${sdn_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset sdn_output_arr

# clean up logs
for i in $sdn_pods; do
  rm "$i"
done

}

auth(){

#Check to make sure the openshift-authentication namespace exits
if [ ! "$(oc get ns openshift-authentication 2>/dev/null)" ]; then
  echo -e "openshift-authentication not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No Auth Pods in Running State\n"
  return 1
else
  # Set auth pods
  auth_pods=$(oc get pods -n openshift-authentication -l app=oauth-openshift --no-headers | awk '{ print $1 }')
fi

# set column names
auth_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# oauth-openshift pod errors
auth_errors_arr=("the server is currently unable to handle the request" "Client.Timeout exceeded while awaiting headers")

for i in $auth_pods; do
  oc logs pod/"$i" -n openshift-authentication > $i
  for val in "${auth_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     auth_output_arr+=("$(echo "openshift-authentication")|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#auth_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${auth_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset auth_output_arr

# clean up logs
for i in $auth_pods; do
  rm "$i"
done

}

kube_controller(){

#Check to make sure the openshift-kube-controller-manager namespace exits
if [ ! "$(oc get ns openshift-kube-controller-manager 2>/dev/null)" ]; then
  echo -e "openshift-kube-controller-manager not found.\n"
  return 1
fi

#Verify pods are in Running State\n
if [ ! "$(oc get pods -n openshift-kube-controller-manager -l app=kube-controller-manager --no-headers --field-selector=status.phase=Running 2>/dev/null)" ]; then
  echo -e "No Auth Pods in Running State\n"
  return 1
else
  # Set kube-controller pods
  kube_controller_pods=$(oc get pods -n openshift-kube-controller-manager -l app=kube-controller-manager --no-headers | awk '{ print $1 }')
fi

# set column names
kube_controller_output_arr=("NAMESPACE|POD|ERROR|COUNT")

# kube-controller-manager pod errors
kube_controller_errors_arr=("the server is currently unable to handle the request")

for i in $kube_controller_pods; do
  oc logs pod/"$i" -n openshift-kube-controller-manager > $i
  for val in "${kube_controller_errors_arr[@]}"; do
    if [[ "$(grep -wc "$val" "$i")" != "0" ]]; then
     kube_controller_output_arr+=("$(echo "openshift-kube-controller-manager")|$(echo "$i")|$(echo "$val")|$(grep -wc "$val" "$i")")
    fi
  done
done

if [ "${#kube_controller_output_arr[1]}" != 0 ]; then
  printf '%s\n' "${kube_controller_output_arr[@]}" | column -t -s '|'
  printf "\n"
fi

unset kube_controller_output_arr

# clean up logs
for i in $kube_controller_pods; do
  rm "$i"
done

}

main(){

#Verify jq is installed
dep_check

run "$1"

}

main "$@"