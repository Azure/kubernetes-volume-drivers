# dysk CSI driver for Kubernetes (Deprecated)

**WARNING**: This driver is in Deprecated currently. Do NOT use this driver in a production environment in its current state.

 - supported Kubernetes version: v1.10.0 ~ v.11.x
 - supported agent OS: Linux 

> Note: This driver only works before v1.12.0 since there is a CSI breaking change in v1.12.0, find details [here](https://github.com/Azure/kubernetes-volume-drivers/issues/8)

# About
This driver allows Kubernetes to use [fast kernel-mode mount/unmount AzureDisk](https://github.com/khenidak/dysk)

# Prerequisite
 - A storage account should be created in the same region as the kubernetes cluster

# Install dysk CSI driver on a kubernetes cluster 
## 1. install dysk CSI driver on every agent node
 - create daemonset to install dysk driver
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/dysk/deployment/dysk-flexvol-installer.yaml
```

 - check daemonset status:
```
watch kubectl describe daemonset dysk-flexvol-installer --namespace=dysk
watch kubectl get po --namespace=dysk -o wide
```

 - install dysk CSI components
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/deployment/csi-dysk-driver.yaml
```

 - check pods status:
```
watch kubectl get po --namespace=dysk -o wide
```
example output:
```
NAME                           READY     STATUS    RESTARTS   AGE       IP            NODE
csi-dysk-7w8vm                 2/2       Running   0          3m        10.240.0.4    k8s-agentpool-66825246-0
csi-dysk-attacher-0            1/1       Running   0          3m        10.240.0.42   k8s-agentpool-66825246-1
csi-dysk-lzsz2                 2/2       Running   0          3m        10.240.0.35   k8s-agentpool-66825246-1
csi-dysk-provisioner-0         1/1       Running   0          3m        10.240.0.37   k8s-agentpool-66825246-1
dysk-flexvol-installer-64hpv   2/2       Running   0          3m        10.240.0.8    k8s-agentpool-66825246-0
dysk-flexvol-installer-m4w6j   2/2       Running   0          3m        10.240.0.90   k8s-master-66825246-0
dysk-flexvol-installer-qnjhj   2/2       Running   0          3m        10.240.0.52   k8s-agentpool-66825246-1
```

# Basic Usage
## 1. create a secret with dysk account name and key
```
kubectl create secret generic dyskcreds --from-literal accountname=ACCOUNT-NAME --from-literal accountkey="ACCOUNT-KEY" --type="azure/dysk"
```

## 2. create a pod with csi dysk driver mount on linux
#### Example#1: Dynamic Provisioning (ReadWriteOnce)
 - Create a dysk CSI storage class
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/storageclass-csi-dysk.yaml
```

 - Create a dysk CSI PVC
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/pvc-csi-dysk.yaml
```
make sure pvc is created successfully
```
watch kubectl describe pvc pvc-csi-dysk
```

 - create a pod with dysk CSI PVC
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/nginx-pod-csi-dysk.yaml
```

#### Example#2: Static Provisioning (ReadOnlyMany)
> Note:
>  - access modes of blobfuse PV supports ReadWriteOnce(RWO), ReadOnlyMany(ROX)
>  - `Pod.Spec.Volumes.PersistentVolumeClaim.readOnly` field should be set as `true` when `accessModes` of PV is set as `ReadOnlyMany`
 - Prerequisite

An Azure disk should be created and formatted in the specified storage account, disk in example#1 could be used.

 - download `pv-csi-dysk-readonly.yaml` file, modify `container`, `blob`, `volumeHandle` fields and create a dysk csi persistent volume(PV)
```
wget https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/pv-csi-dysk-readonly.yaml
vi pv-csi-dysk-readonly.yaml
kubectl create -f pv-csi-dysk-readonly.yaml
```

 - create a dysk csi persistent volume claim(PVC)
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/pvc-csi-dysk-readonly.yaml
```

 - check status of PV & PVC until its Status changed to `Bound`
```
kubectl get pv
kubectl get pvc
```
 
 - create a pod with dysk csi PVC
```
kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/csi/dysk/nginx-pod-csi-dysk-readonly.yaml
```

## 3. enter the pod container to do validation
 - watch the status of pod until its Status changed from `Pending` to `Running`
```
watch kubectl describe po nginx-csi-dysk
```
 - enter the pod container

```
kubectl exec -it nginx-csi-dysk -- bash
root@nginx-csi-dysk:/# df -h
Filesystem         Size  Used Avail Use% Mounted on
overlay            291G  3.6G  288G   2% /
tmpfs              3.4G     0  3.4G   0% /dev
tmpfs              3.4G     0  3.4G   0% /sys/fs/cgroup
/dev/sda1          291G  3.6G  288G   2% /etc/hosts
/dev/dyskPKFDLeec  4.8G   10M  4.6G   1% /mnt/disk
shm                 64M     0   64M   0% /dev/shm
tmpfs              3.4G   12K  3.4G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs              3.4G     0  3.4G   0% /sys/firmware
```
In the above example, there is a `/mnt/disk` directory mounted as dysk filesystem.

 - check pod with readOnly disk mount
 ```
 root@nginx-csi-dysk:/mnt/disk# touch /mnt/disk/a
touch: cannot touch '/mnt/disk/a': Read-only file system
 ```

### Links
 - [dysk - Fast kernel-mode mount/unmount of AzureDisk](https://github.com/khenidak/dysk)
 - [Analysis of the CSI Spec](https://blog.thecodeteam.com/2017/11/03/analysis-csi-spec/)
 - [CSI Drivers](https://github.com/kubernetes-csi/drivers)
 - [Container Storage Interface (CSI) Specification](https://github.com/container-storage-interface/spec)
