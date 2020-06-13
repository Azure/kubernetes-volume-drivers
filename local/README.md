# Local Persistent Volume support on Azure
The goal of this repository is to enable Kubernetes workloads using local disks, e.g. Azure [LSv2](https://docs.microsoft.com/en-us/azure/virtual-machines/lsv2-series) VM with NVMe SSD, [local temporary disk](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/managed-disks-overview#temporary-disk).

This repository leverages [local volume static provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner) to manage the PersistentVolume lifecycle for pre-allocated disks by detecting, formatting and creating PVs for each local disk on the agent node, and cleaning up the disks when released.

### Supported matrix
 - Kubernetes version: 1.14+
 - OS: Linux

## Usage
### 1. Install local volume static provisioner on a Kubernetes cluster
#### Option#1: discover NVMe SSD(`/dev/nvme*`) disks
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/local/local-pv-provisioner-nvmedisk.yaml
```

#### Option#2: discover temp(`/dev/sdb1`) disk
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/local/local-pv-provisioner-tempdisk.yaml
```
> you can also download [local-pv-provisioner-nvmedisk.yaml](https://github.com/Azure/kubernetes-volume-drivers/blob/master/local/local-pv-provisioner-nvmedisk.yaml) and modify `namePattern`, `fsType` fields to match other pre-allocated disks.

 - Persistent volumes would be created after provisioner daemonset started
> In following example, one PV would be created per one NVMe disk
```console
# kubectl get pv
NAME                CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
local-pv-9042a3d7   1788Gi     RWO            Delete           Available           fast-disks              4s
local-pv-d25649a0   1788Gi     RWO            Delete           Available           fast-disks              4s

# kubectl get pv local-pv-9042a3d7 -o yaml
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
  storageClassName: fast-disks
  volumeMode: Filesystem
status:
  phase: Available
```

### 2. Create a new local volume storage class(with name `fast-disks`)
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/local/local-pv-storageclass.yaml
```

### 3. Create a PVC and pod to consume local volume PV
```console
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/local/deployment.yaml
```

### 4. Enter the pod to verify
> in below example, NVMe disk has been formatted as `ext4` file system 
```console
# kubectl exec -it deployment-localdisk-56cf8d4c5c-clwbl bash
root@deployment-localdisk-56cf8d4c5c-clwbl:/# df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/sda1        97G   12G   86G  12% /etc/hosts
/dev/nvme0n1    1.8T   68M  1.8T   1% /mnt/localdisk
...
```

#### Notes
If `reclaimPolicy` is set as `Delete` in [local volume storage class](https://github.com/Azure/kubernetes-volume-drivers/blob/6846c13ebc6a8d8682f6265ae4ae588857de31ab/local/local-pv-storageclass.yaml#L8), data will be cleaned up after PVC deleted, local volume PV would be in `Released` status, after around 5min by default, PV status would be changed to `Bound`, user could tune [minResyncPeriod](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner/blob/master/docs/provisioner.md#configuration) value to make PV status refresh more quickly.

### Links
 - [Local Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local)
 - [Kubernetes 1.14: Local Persistent Volumes GA](https://kubernetes.io/blog/2019/04/04/kubernetes-1.14-local-persistent-volumes-ga/)
 - [local volume static provisioner](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner)
