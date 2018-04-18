# hostpath CSI driver example

## Install hostpath CSI driver on a kubernetes cluster 
 - Set up [External Attacher](https://github.com/kubernetes-csi/external-attacher), [External Provisioner](https://github.com/kubernetes-csi/external-provisioner), [Driver Registrar](https://github.com/kubernetes-csi/driver-registrar), [hostpath driver](https://github.com/kubernetes-csi/drivers/tree/master/pkg/hostpath) and ClusterRole permissions 
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/hostpath/deployment/csi-hostpath-driver.yaml
```

 - watch the status of all component pods until its `Status` changed from `Pending` to `Running`
```
$ kubectl get po -o wide --namespace=hostpath
NAME                         READY     STATUS    RESTARTS   AGE       IP            NODE
csi-hostpath-attacher-0      1/1       Running   0          19m       10.240.0.18   k8s-agentpool-66825246-0
csi-hostpath-n68n2           2/2       Running   0          19m       10.240.0.4    k8s-agentpool-66825246-0
csi-hostpath-provisioner-0   1/1       Running   0          19m       10.240.0.30   k8s-agentpool-66825246-0
csi-hostpath-zp2dg           2/2       Running   0          19m       10.240.0.35   k8s-agentpool-66825246-1
```

## Basic Usage
### 1. Create a hostpath CSI storage class
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/hostpath/storageclass-csi-hostpath.yaml
```

### 2. Create a hostpath CSI PVC
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/hostpath/pvc-csi-hostpath.yaml
```
make sure pvc is created successfully
```
watch kubectl describe pvc pvc-csi-hostpath
```

### 3. create a pod with hostpath CSI PVC
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/csi/hostpath/nginx-pod-csi-hostpath.yaml
```

### 4. enter the pod container to do validation
```
azureuser@k8s-master-87187153-0:~$ kubectl exec -it  nginx-csi-hostpath -- bash
root@nginx-csi-hostpath:/# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay          30G  8.9G   21G  31% /
tmpfs           3.4G     0  3.4G   0% /dev
tmpfs           3.4G     0  3.4G   0% /sys/fs/cgroup
overlay          30G  8.9G   21G  31% /data
/dev/sda1        30G  8.9G   21G  31% /etc/hosts
shm              64M     0   64M   0% /dev/shm
tmpfs           3.4G   12K  3.4G   1% /run/secrets/kubernetes.io/serviceaccount
```

#### Note
 - CSI hostpath driver would mkdir under `/var/lib/kubelet/pods/5a6d98a3-1c57-11e8-a48d-000d3afdbef1/volumes/kubernetes.io~csi/kubernetes-dynamic-pvc-5a7519c9-1c57-11e8-99dd-bab516dca496/mount`, mount to `/data` dir in the above example
 - clean up all clusterroles & clusterrolebindings:
```
kubectl delete clusterrole hostpath:external-provisioner-runner
kubectl delete clusterrole hostpath:external-attacher-runner
kubectl delete clusterrole csi-hostpath
kubectl delete clusterrolebinding csi-hostpath-provisioner-role
kubectl delete clusterrolebinding csi-hostpath-attacher-role
kubectl delete clusterrolebinding csi-hostpath
```

#### Links
[Introducing Container Storage Interface (CSI) Alpha for Kubernetes](http://blog.kubernetes.io/2018/01/introducing-container-storage-interface.html)

[Kubernetes CSI Documentation](https://kubernetes-csi.github.io/docs/Home.html)

[CSI Volume Plugins in Kubernetes Design Doc](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/storage/container-storage-interface.md)
