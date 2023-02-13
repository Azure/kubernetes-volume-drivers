# Test script usage guide
## Test scenario 1: attach detach test
We test attach/detach disks and achieve time with PV creation, attach and detach.
- PV creation P50/P90/P99: 50%/90%/99% number of PVC are in Bound state.
- attach disks P50/P90/P99: 50%/90%/99% number of Pod are in Running state.
- detach disks P50/P90/P99: 50%/90%/99% number of volumeattachments are in false state.

`attach_detach_test.sh` is used for this test scenario.
e.g. We want to test 300 pods attach/detach with default sc and write result in file.txt.
- Option#1. remote test
```
curl -skSL https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/test/attach_detach_test.sh | bash -s 300 default file.txt --
```
- Option#2. local test
```
sh attach_detach_test.sh 300 default file.txt
```
### Loop attach/detach test script in background is supported.
use `cyc_attach_detach_test.sh` to loop attach/detach test in background.

e.g. test 1000 pods attach/detach with default sc and write result in test1000v1.txt for 30 times in background. When one attach/detach test is finished, sleep for 3 minutes to avoid client throttling.
- Option#1. remote test
```
curl -skSL https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/test/cyc_attach_detach_test.sh | nohup bash -s 1000 default test1000v1.txt 30 & 
```
- Option#2. local test
```
nohup sh cyc_attach_detach_test.sh 1000 default test1000v1.txt 30 &
```
### Portworx test scenario
Because portworx has no attach operation, we use pv deletion for detach test. Use `attach_detach_test_portworx.sh` and `cyc_attach_detach_test_portworx.sh` for attach/detach test in portworx test scenario.
## Test scenario 2: pod failover test
In this scenario, we test 1 pod 3 pvc pod failover test. The time from pod deleted to pod ready will be calculated in the test script. Use `pod_failover_test.sh` for test.

e.g. test 1 pod 3 pvc pod failover test for 300 times and write results in file.txt in background.
- Option#1. remote test
```
curl -skSL https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/test/pod_failover_test.sh | nohup bash -s 300 file.txt & 
```
- Option#2. local test
```
nohup sh pod_failover_test.sh 300 file.txt &
```
