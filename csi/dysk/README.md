# dysk CSI driver for Kubernetes (Preview)
 - supported Kubernetes version: available from v1.10.0
 - supported agent OS: Linux 

# About
This driver allows Kubernetes to use [fast kernel-mode mount/unmount AzureDisk](https://github.com/khenidak/dysk)

# Prerequisite
 - A storage account should be created in the same region as the kubernetes cluster

# Install dysk CSI driver on a kubernetes cluster 
## 1. install dysk CSI driver on every agent node
 - create daemonset to install dysk driver
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/dysk/deployment/dysk-flexvol-installer.yaml
```

 - check daemonset status:
```
kubectl describe daemonset dysk-flexvol-installer --namespace=flex
kubectl get po --namespace=flex
```

 - install dysk CSI componentes
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/dysk/deployment/csi-provisioner.yaml
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/dysk/deployment/csi-attacher.yaml
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/dysk/deployment/csi-dysk-driver.yaml
```

 - check pods status:
```
kubectl get po
```
example output:
```
NAME                READY     STATUS    RESTARTS   AGE
csi-attacher-0      1/1       Running   1          1m
csi-dysk-m8lqp      2/2       Running   0          1m
csi-provisioner-0   1/1       Running   0          2m
```

# Basic Usage
## 1. create a secret which stores dysk account name and password
```
kubectl create secret generic dyskcreds --from-literal username=USERNAME --from-literal password="PASSWORD" --type="azure/dysk"
```

## 2. create a pod with csi dysk driver mount on linux
 - Create a dysk CSI storage class
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/dysk/storageclass-csi-dysk.yaml
```

### ReadWriteOnce example
 - Create a dysk CSI ReadWriteOnce PVC
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/dysk/pvc-csi-dysk.yaml
```
make sure pvc is created successfully
```
watch kubectl describe pvc pvc-csi-dysk
```

 - create a pod with dysk CSI PVC
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/dysk/nginx-pod-csi-dysk.yaml
```

## 3. enter the pod container to do validation
 - watch the status of pod until its Status changed from `Pending` to `Running`
```
watch kubectl describe po nginx-flex-dysk
```
 - enter the pod container
kubectl exec -it nginx-csi-dysk -- bash

```
root@nginx-csi-dysk:/# df -h
Filesystem         Size  Used Avail Use% Mounted on
overlay            291G  3.6G  288G   2% /
tmpfs              3.4G     0  3.4G   0% /dev
tmpfs              3.4G     0  3.4G   0% /sys/fs/cgroup
/dev/sda1          291G  3.6G  288G   2% /etc/hosts
/dev/dyskPKFDLeec  4.8G   10M  4.6G   1% /data
shm                 64M     0   64M   0% /dev/shm
tmpfs              3.4G   12K  3.4G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs              3.4G     0  3.4G   0% /sys/firmware
```
In the above example, there is a `/data` directory mounted as dysk filesystem.


### Links
[dysk - Fast kernel-mode mount/unmount of AzureDisk](https://github.com/khenidak/dysk)
