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
If `reclaimPolicy` is set as `Delete` in [local volume storage class](https://github.com/Azure/kubernetes-volume-drivers/blob/6846c13ebc6a8d8682f6265ae4ae588857de31ab/local/local-pv-storageclass.yaml#L8), data will be cleaned up after PVC deleted, local volume PV would be in `Released` status, after around 3 minutes, PV status would be changed to `Bound`, user could tune [minResyncPeriod](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/provisioner.md#configuration) value to make PV status refresh more quickly.

#### Troubleshooting
<details><summary>get local-volume-provisioner logs</summary>
<pre>
kubectl logs local-volume-provisioner-m8fbj -n kube-system
</pre>
</details>

<details><summary>example logs</summary>

```
I0321 11:21:50.707052       1 common.go:348] StorageClass "local-disk" configured with MountDir "/dev", HostDir "/dev", VolumeMode "Filesystem", FsType "ext4", BlockCleanerCommand ["/scripts/quick_reset.sh"], NamePattern "nvme*"
I0321 11:21:50.707144       1 main.go:66] Loaded configuration: {StorageClassConfig:map[local-disk:{HostDir:/dev MountDir:/dev BlockCleanerCommand:[/scripts/quick_reset.sh] VolumeMode:Filesystem FsType:ext4 NamePattern:nvme*}] NodeLabelsForPV:[] UseAlphaAPI:false UseJobForCleaning:false MinResyncPeriod:{Duration:5m0s} UseNodeNameOnly:false LabelsForPV:map[] SetPVOwnerRef:false}
I0321 11:21:50.707174       1 main.go:67] Ready to run...
W0321 11:21:50.707180       1 main.go:76] MY_NAMESPACE environment variable not set, will be set to default.
W0321 11:21:50.707185       1 main.go:82] JOB_CONTAINER_IMAGE environment variable not set.
I0321 11:21:50.707320       1 common.go:425] Creating client using in-cluster config
I0321 11:21:50.751109       1 main.go:88] Starting controller
I0321 11:21:50.751161       1 main.go:105] Starting metrics server at :8080
I0321 11:21:50.751236       1 controller.go:47] Initializing volume cache
I0321 11:21:50.752642       1 mount_linux.go:163] Detected OS without systemd
I0321 11:21:50.855049       1 controller.go:116] Controller started
I0321 11:21:50.855755       1 discovery.go:423] Found new volume at host path "/dev/nvme1n1" with capacity 1920383410176, creating Local PV "local-pv-1de3995e", required volumeMode "Filesystem"
I0321 11:21:50.873281       1 discovery.go:457] Created PV "local-pv-1de3995e" for volume at "/dev/nvme1n1"
I0321 11:21:50.873346       1 discovery.go:423] Found new volume at host path "/dev/nvme3n1" with capacity 1920383410176, creating Local PV "local-pv-20d38638", required volumeMode "Filesystem"
I0321 11:21:50.873387       1 cache.go:55] Added pv "local-pv-1de3995e" to cache
I0321 11:21:50.878969       1 cache.go:55] Added pv "local-pv-20d38638" to cache
I0321 11:21:50.879557       1 discovery.go:457] Created PV "local-pv-20d38638" for volume at "/dev/nvme3n1"
I0321 11:21:50.879657       1 discovery.go:423] Found new volume at host path "/dev/nvme0n1" with capacity 1920383410176, creating Local PV "local-pv-2d08f517", required volumeMode "Filesystem"
I0321 11:21:50.882559       1 cache.go:64] Updated pv "local-pv-1de3995e" to cache
I0321 11:21:50.885724       1 discovery.go:457] Created PV "local-pv-2d08f517" for volume at "/dev/nvme0n1"
I0321 11:21:50.885773       1 cache.go:55] Added pv "local-pv-2d08f517" to cache
I0321 11:21:50.885822       1 discovery.go:423] Found new volume at host path "/dev/nvme2n1" with capacity 1920383410176, creating Local PV "local-pv-df7e5119", required volumeMode "Filesystem"
I0321 11:21:50.888347       1 cache.go:64] Updated pv "local-pv-20d38638" to cache
I0321 11:21:50.892143       1 cache.go:55] Added pv "local-pv-df7e5119" to cache
I0321 11:21:50.892260       1 discovery.go:457] Created PV "local-pv-df7e5119" for volume at "/dev/nvme2n1"
E0321 11:21:50.892413       1 discovery.go:221] Failed to discover local volumes: 4 error(s) while discovering volumes: [Skipping file "/dev/nvme3": not a directory nor block device Skipping file "/dev/nvme2": not a directory nor block device Skipping file "/dev/nvme1": not a directory nor block device Skipping file "/dev/nvme0": not a directory nor block device]
```
 
```
 root@aks-l32s2-91958816-vmss000000:/# mount | grep nvme | sort | uniq
/dev/nvme0n1 on /var/lib/kubelet/plugins/kubernetes.io/local-volume/mounts/local-pv-2d08f517 type ext4 (rw,relatime)
/dev/nvme0n1 on /var/lib/kubelet/pods/2e2c41f2-2de9-4c9a-ad9f-684f1e831ca5/volumes/kubernetes.io~local-volume/local-pv-2d08f517 type ext4 (rw,relatime)
/dev/nvme1n1 on /var/lib/kubelet/plugins/kubernetes.io/local-volume/mounts/local-pv-1de3995e type ext4 (rw,relatime)
/dev/nvme1n1 on /var/lib/kubelet/pods/7d2b62cb-2e0b-4841-90af-f8f719c20f72/volumes/kubernetes.io~local-volume/local-pv-1de3995e type ext4 (rw,relatime)
/dev/nvme2n1 on /var/lib/kubelet/plugins/kubernetes.io/local-volume/mounts/local-pv-df7e5119 type ext4 (rw,relatime)
/dev/nvme2n1 on /var/lib/kubelet/pods/c430b76a-743a-4382-80ce-75bac2b7a349/volumes/kubernetes.io~local-volume/local-pv-df7e5119 type ext4 (rw,relatime)
/dev/nvme3n1 on /var/lib/kubelet/plugins/kubernetes.io/local-volume/mounts/local-pv-20d38638 type ext4 (rw,relatime)
/dev/nvme3n1 on /var/lib/kubelet/pods/7bdfd3ae-7a42-4c1b-af4d-ef63436cd415/volumes/kubernetes.io~local-volume/local-pv-20d38638 type ext4 (rw,relatime)
```

</details>

### Links
 - [Local Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local)
 - [Kubernetes 1.14: Local Persistent Volumes GA](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)
 - [local volume static provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)
