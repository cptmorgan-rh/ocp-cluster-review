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
NAMESPACE       POD                      ERROR                                                                                                     COUNT
openshift-etcd  etcd-ocp-85wpv-master-0  waiting for ReadIndex response took too long, retrying                                                    171
openshift-etcd  etcd-ocp-85wpv-master-0  etcdserver: request timed out                                                                             615
openshift-etcd  etcd-ocp-85wpv-master-0  "apply request took too long"                                                                             16480
openshift-etcd  etcd-ocp-85wpv-master-0  "leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk"  42
openshift-etcd  etcd-ocp-85wpv-master-0  local node might have slow network                                                                        10
openshift-etcd  etcd-ocp-85wpv-master-0  elected leader                                                                                            9
openshift-etcd  etcd-ocp-85wpv-master-0  lost leader                                                                                               9
openshift-etcd  etcd-ocp-85wpv-master-0  lease not found                                                                                           4
openshift-etcd  etcd-ocp-85wpv-master-1  waiting for ReadIndex response took too long, retrying                                                    21
openshift-etcd  etcd-ocp-85wpv-master-1  etcdserver: request timed out                                                                             112
openshift-etcd  etcd-ocp-85wpv-master-1  slow fdatasync                                                                                            3
openshift-etcd  etcd-ocp-85wpv-master-1  "apply request took too long"                                                                             11391
openshift-etcd  etcd-ocp-85wpv-master-1  "leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk"  75
openshift-etcd  etcd-ocp-85wpv-master-1  local node might have slow network                                                                        1
openshift-etcd  etcd-ocp-85wpv-master-1  elected leader                                                                                            4
openshift-etcd  etcd-ocp-85wpv-master-1  lost leader                                                                                               3
openshift-etcd  etcd-ocp-85wpv-master-1  lease not found                                                                                           4
openshift-etcd  etcd-ocp-85wpv-master-1  sending buffer is full                                                                                    101
openshift-etcd  etcd-ocp-85wpv-master-2  waiting for ReadIndex response took too long, retrying                                                    48
openshift-etcd  etcd-ocp-85wpv-master-2  slow fdatasync                                                                                            10
openshift-etcd  etcd-ocp-85wpv-master-2  "apply request took too long"                                                                             20225
openshift-etcd  etcd-ocp-85wpv-master-2  "leader failed to send out heartbeat on time; took too long, leader is overloaded likely from slow disk"  8
openshift-etcd  etcd-ocp-85wpv-master-2  elected leader                                                                                            8
openshift-etcd  etcd-ocp-85wpv-master-2  lost leader                                                                                               8
openshift-etcd  etcd-ocp-85wpv-master-2  lease not found                                                                                           4
openshift-etcd  etcd-ocp-85wpv-master-2  sending buffer is full                                                                                    3229

Stats about etcd 'took long' messages: etcd-ocp-85wpv-master-0
	First Occurance: 2023-08-22T21:55:00.293372109Z
	Last Occurance: 2023-08-23T07:21:15.759470164Z
	Maximum: 24447.446878000ms
	Minimum: 100.3548ms
	Median: 502.38111ms
	Average: 1597.2489397344339ms
	Expected: 200ms

Stats about etcd 'took long' messages: etcd-ocp-85wpv-master-1
	First Occurance: 2023-08-23T02:29:33.089622969Z
	Last Occurance: 2023-08-26T16:36:06.369371064Z
	Maximum: 39928.879989000ms
	Minimum: 100.824712ms
	Median: 1020.7342165ms
	Average: 6920.606041005108ms
	Expected: 200ms

Stats about etcd 'took long' messages: etcd-ocp-85wpv-master-2
	First Occurance: 2023-08-22T19:45:37.728011585Z
	Last Occurance: 2023-08-24T15:00:00.338017683Z
	Maximum: 21744.143655000ms
	Minimum: 105.300525ms
	Median: 983.8026565ms
	Average: 6366.830047261907ms
	Expected: 200ms

Stats about etcd 'slow fdatasync' messages: etcd-ocp-85wpv-master-0
	First Occurance: 2023-08-22T22:48:28.409721624Z
	Last Occurance: 2023-08-23T03:21:49.293376168Z
	Maximum: 5368.560878000ms
	Minimum: 1024.725187000ms
	Median: 1861.773876000ms
	Average: 2282.4877315555555ms
	Expected: 1s

Stats about etcd 'slow fdatasync' messages: etcd-ocp-85wpv-master-1
	First Occurance: 2023-08-23T02:46:24.839624930Z
	Last Occurance: 2023-08-23T02:46:24.839624930Z
	Maximum: 4580.619091000ms
	Minimum: 4580.619091000ms
	Median: 4580.619091000ms
	Average: 4580.619091ms
	Expected: 1s

Stats about etcd 'slow fdatasync' messages: etcd-ocp-85wpv-master-2
	First Occurance: 2023-08-22T19:47:18.380266659Z
	Last Occurance: 2023-08-23T03:34:53.232922865Z
	Maximum: 2970.156241000ms
	Minimum: 1124.231775000ms
	Median: 1844.3475265000002ms
	Average: 1948.1355376249999ms
	Expected: 1s

etcd DB Compaction times: etcd-ocp-85wpv-master-0
	Maximum: 429921.463412000ms
	Minimum: 105.896533ms
	Median: 110.189392ms
	Average: 790.6587394749773ms

etcd DB Compaction times: etcd-ocp-85wpv-master-1
	Maximum: 429921.463412000ms
	Minimum: 105.032466ms
	Median: 109.717624ms
	Average: 491.03446315230514ms

etcd DB Compaction times: etcd-ocp-85wpv-master-2
	Maximum: 429921.463412000ms
	Minimum: 105.032466ms
	Median: 109.87619649999999ms
	Average: 537.0147174835607ms

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
