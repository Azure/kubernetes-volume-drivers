# Local Persistent Volume support on Azure
The goal of this repository is to enable Kubernetes workloads using local disks, e.g. Azure [LSv2](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv2-series) VM with NVMe SSD, [local temporary disk](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/managed-disks-overview#temporary-disk).

This repository leverages [local volume static provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) to manage the PersistentVolume lifecycle for pre-allocated disks by detecting, formatting and creating PVs for each local disk on the agent node, and cleaning up the disks when released.

### Supported matrix
 - Kubernetes version: 1.14+
 - OS: Linux

## Usage
### 1. Create a new local volume storage class
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/v2.5.0/local/local-pv-storageclass.yaml
```

### 2. Install local volume static provisioner on a Kubernetes cluster
> use only one `local-pv-provisioner-xxx.yaml` config file, there would be conflict if applying multiple config files on one cluster
#### Option#1: discover NVMe SSD(`/dev/nvme*`) disks
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/v2.5.0/local/local-pv-provisioner-nvmedisk.yaml
```

#### Option#2: discover temp(`/dev/sdb1`) disk
> to make sure temp disk is not used, run following command to unmount temp disk first
> ```console
> kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/v2.5.0/local/umount-mnt.yaml
> ```

```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/v2.5.0/local/local-pv-provisioner-tempdisk.yaml
```
> you can also download [local-pv-provisioner-nvmedisk.yaml](https://github.com/Azure/kubernetes-volume-drivers/blob/v2.5.0/local/local-pv-provisioner-nvmedisk.yaml) and modify `namePattern`, `fsType` fields to match other pre-allocated disks.

 - Persistent volumes would be created after provisioner daemonset started
> In following example, one PV would be created per one NVMe disk

<details><summary>kubectl get pv</summary>
<pre>
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
local-pv-9042a3d7   1788Gi     RWO            Delete           Available           local-disk              4s
local-pv-d25649a0   1788Gi     RWO            Delete           Available           local-disk              4s
</pre>
</details>

<details><summary>kubectl get pv local-pv-9042a3d7 -o yaml</summary>

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
...
  name: local-pv-9042a3d7
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1788Gi
  local:
    fsType: ext4
    path: /dev/nvme0n1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - aks-agentpool-39784301-0
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-disk
  volumeMode: Filesystem
status:
  phase: Available
```

</details>

### 3. Create a PVC and pod to consume local volume PV
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/v2.5.0/local/statefulset.yaml
```

### 4. Enter the pod to verify
> in below example, NVMe disk has been formatted as `ext4` file system

<details><summary>check file system inside pod</summary>
<pre>
kubectl exec -it statefulset-local-0 -- df -h
</pre>

<pre>
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sda1        97G   12G   86G  12% /etc/hosts
/dev/nvme0n1    1.8T   68M  1.8T   1% /mnt/localdisk
...
</pre>

</details>

#### Notes
If `reclaimPolicy` is set as `Delete` in [local volume storage class](https://github.com/Azure/kubernetes-volume-drivers/blob/6846c13ebc6a8d8682f6265ae4ae588857de31ab/local/local-pv-storageclass.yaml#L8), data will be cleaned up after PVC deleted, local volume PV would be in `Released` status, after around 5min by default, PV status would be changed to `Bound`, user could tune [minResyncPeriod](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/provisioner.md#configuration) value to make PV status refresh more quickly.

#### Troubleshooting
<details><summary>get local-volume-provisioner logs</summary>
<pre>
kubectl logs local-volume-provisioner-m8fbj -n kube-system
</pre>
</details>

<details><summary>example logs</summary>

```
I0530 12:43:11.874618       1 common.go:344] StorageClass "local-disk" configured with MountDir "/dev", HostDir "/dev", VolumeMode "Filesystem", FsType "xfs", BlockCleanerCommand ["/scripts/shred.sh" "2"], NamePattern "nvme*"
I0530 12:43:11.874684       1 main.go:63] Loaded configuration: {StorageClassConfig:map[local-disk:{HostDir:/dev MountDir:/dev BlockCleanerCommand:[/scripts/shred.sh 2] VolumeMode:Filesystem FsType:xfs NamePattern:nvme*}] NodeLabelsForPV:[] UseAlphaAPI:false UseJobForCleaning:false MinResyncPeriod:{Duration:5m0s} UseNodeNameOnly:false LabelsForPV:map[] SetPVOwnerRef:false}
I0530 12:43:11.874713       1 main.go:64] Ready to run...
W0530 12:43:11.874724       1 main.go:73] MY_NAMESPACE environment variable not set, will be set to default.
W0530 12:43:11.874737       1 main.go:79] JOB_CONTAINER_IMAGE environment variable not set.
I0530 12:43:11.874963       1 common.go:407] Creating client using in-cluster config
I0530 12:43:11.945316       1 main.go:85] Starting controller
I0530 12:43:11.945354       1 main.go:101] Starting metrics server at :8080
I0530 12:43:11.945398       1 controller.go:47] Initializing volume cache
I0530 12:43:11.945607       1 mount_linux.go:163] Detected OS without systemd
I0530 12:43:12.045905       1 controller.go:111] Controller started
I0530 12:43:12.046863       1 discovery.go:287] file(termination-log) under(/dev) does not match pattern(nvme*)
I0530 12:43:12.046979       1 discovery.go:287] file(sdb1) under(/dev) does not match pattern(nvme*)
I0530 12:43:12.046991       1 discovery.go:287] file(dvd) under(/dev) does not match pattern(nvme*)

I1205 11:53:42.771500       1 cache.go:64] Updated pv "local-pv-8739a5e2" to cache
I1205 11:53:45.552542       1 deleter.go:195] Start cleanup for pv local-pv-8739a5e2
I1205 11:53:45.552944       1 deleter.go:275] Deleting PV block volume "local-pv-8739a5e2" device hostpath "/dev/sdb1", mountpath "/dev/sdb1"
I1205 11:53:45.624199       1 deleter.go:319] Cleanup pv "local-pv-8739a5e2": StderrBuf - "shred: /dev/sdb1: pass 1/3 (random)..."
I1205 11:53:50.007271       1 deleter.go:319] Cleanup pv "local-pv-8739a5e2": StderrBuf - "shred: /dev/sdb1: pass 1/3 (random)...564MiB/16GiB 3%"
I1205 11:53:55.006489       1 deleter.go:319] Cleanup pv "local-pv-8739a5e2": StderrBuf - "shred: /dev/sdb1: pass 1/3 (random)...1.1GiB/16GiB 7%"
I1205 11:54:00.017742       1 deleter.go:319] Cleanup pv "local-pv-8739a5e2": StderrBuf - "shred: /dev/sdb1: pass 1/3 (random)...1.7GiB/16GiB 10%"
I1205 11:54:05.006582       1 deleter.go:319] Cleanup pv "local-pv-8739a5e2": StderrBuf - "shred: /dev/sdb1: pass 1/3 (random)...2.1GiB/16GiB 13%"
```

</details>

### Links
 - [Local Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local)
 - [Kubernetes 1.14: Local Persistent Volumes GA](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)
 - [local volume static provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)
