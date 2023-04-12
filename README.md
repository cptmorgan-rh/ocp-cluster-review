OpenShift Cluster Review
===========================================

DESCRIPTION
------------

The purpose of this script is to quickly search logs for known issues in an OpenShift Cluster.

PREREQUISITES
------------

This script requires jq and cluster-admin access to a cluster.

INSTALLATION
------------
* Copy ocp-cluster-review.sh to a location inside of your $PATH

USAGE
------------

```bash
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
```

SAMPLE OUTPUT
------------

```bash
$ ocp-cluster-review.sh --all
NAMESPACE       POD                      ERROR                                 COUNT
openshift-etcd  etcd-ocp-85wpv-master-0  took too long                         2331
openshift-etcd  etcd-ocp-85wpv-master-0  local node might have slow network    6
openshift-etcd  etcd-ocp-85wpv-master-0  elected leader                        1
openshift-etcd  etcd-ocp-85wpv-master-0  lost leader                           1
openshift-etcd  etcd-ocp-85wpv-master-1  took too long                         14177
openshift-etcd  etcd-ocp-85wpv-master-1  local node might have slow network    14
openshift-etcd  etcd-ocp-85wpv-master-1  elected leader                        7
openshift-etcd  etcd-ocp-85wpv-master-1  lost leader                           6
openshift-etcd  etcd-ocp-85wpv-master-1  failed to send out heartbeat on time  4310
openshift-etcd  etcd-ocp-85wpv-master-2  took too long                         10008
openshift-etcd  etcd-ocp-85wpv-master-2  local node might have slow network    8
openshift-etcd  etcd-ocp-85wpv-master-2  elected leader                        9
openshift-etcd  etcd-ocp-85wpv-master-2  lost leader                           8
openshift-etcd  etcd-ocp-85wpv-master-2  failed to send out heartbeat on time  484

Stats about last 500 etcd 'took long' messages: etcd-ocp4-85wpv-master-0
	Max: 1393.604461ms
	Min: 200.102143ms
	Avg: 361ms
	Expected: 200ms

Stats about last 500 etcd 'took long' messages: etcd-ocp4-85wpv-master-1
	Max: 1402.816156ms
	Min: 200.220565ms
	Avg: 327ms
	Expected: 200ms

Stats about last 500 etcd 'took long' messages: etcd-ocp4-85wpv-master-2
	Max: 5749.69575ms
	Min: 200.196156ms
	Avg: 572ms
	Expected: 200ms

etcd DB Compaction times: etcd-ocp4-85wpv-master-0
	Max: 453.066099ms
	Min: 165.595496ms
	Avg: 182ms

etcd DB Compaction times: etcd-ocp4-85wpv-master-1
	Max: 548.300888ms
	Min: 164.605164ms
	Avg: 182ms

etcd DB Compaction times: etcd-ocp4-85wpv-master-2
	Max: 453.216023ms
	Min: 166.309408ms
	Avg: 183ms

NAMESPACE                 POD                                ERROR                            COUNT
openshift-kube-apiserver  kube-apiserver-ocp4-85wpv-master-0  timeout or abort while handling  1
openshift-kube-apiserver  kube-apiserver-ocp4-85wpv-master-1  timeout or abort while handling  264
openshift-kube-apiserver  kube-apiserver-ocp4-85wpv-master-2  timeout or abort while handling  30

NAMESPACE                 POD                                          ERROR                                                                        COUNT
openshift-kube-scheduler  openshift-kube-scheduler-ocp4-85wpv-master-2  net/http: request canceled (Client.Timeout exceeded while awaiting headers)  1

NAMESPACE      POD                ERROR                   COUNT
openshift-dns  dns-default-66kzc  i/o timeout             171
openshift-dns  dns-default-66kzc  client connection lost  11
openshift-dns  dns-default-8s8md  i/o timeout             7119
openshift-dns  dns-default-gtzbq  i/o timeout             6201
openshift-dns  dns-default-gtzbq  client connection lost  3
openshift-dns  dns-default-lns6x  i/o timeout             20
openshift-dns  dns-default-q6wql  i/o timeout             1
openshift-dns  dns-default-q6wql  client connection lost  3
openshift-dns  dns-default-s6pnv  client connection lost  3

NAMESPACE          POD                              ERROR                                         COUNT
openshift-ingress  router-default-85fdd489f9-mnw5w  unable to find service                        2
openshift-ingress  router-default-85fdd489f9-mnw5w  Failed to make webhook authenticator request  3
openshift-ingress  router-default-85fdd489f9-zwjlm  unable to find service                        2
openshift-ingress  router-default-85fdd489f9-zwjlm  Failed to make webhook authenticator request  1

NAMESPACE                 POD                               ERROR                                                 COUNT
openshift-authentication  oauth-openshift-85b74fff74-fxrbb  the server is currently unable to handle the request  1
openshift-authentication  oauth-openshift-85b74fff74-gwrzn  the server is currently unable to handle the request  2
openshift-authentication  oauth-openshift-85b74fff74-gwrzn  Client.Timeout exceeded while awaiting headers        1
openshift-authentication  oauth-openshift-85b74fff74-zqgq5  the server is currently unable to handle the request  1

NAMESPACE                          POD                                         ERROR                                                 COUNT
openshift-kube-controller-manager  kube-controller-manager-ocp-85wpv-master-2  the server is currently unable to handle the request  104
```

AUTHOR
------
Morgan Peterman
