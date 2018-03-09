# blobfuse flex volume driver for Kubernetes (Preview)
 - supported Kubernetes version: v1.8, v1.9
 - supported agent OS: Linux 

# About
[azure-storage-fuse(blobfuse)](https://github.com/Azure/azure-storage-fuse) allows Linux based Kubernetes to access virtual filesystem backed by the Azure Blob storage.

# Prerequisite
User needs to create an storage account and a container in the same region with the kubernetes cluster and provide storage account name, account key and container name in below example.

# Install blobfuse driver on a kubernetes cluster
## 1. config kubelet service (skip this step in [AKS](https://azure.microsoft.com/en-us/services/container-service/) or from [acs-engine](https://github.com/Azure/acs-engine) v0.12.0)
specify `volume-plugin-dir` in kubelet service config 
```
sudo vi /etc/systemd/system/kubelet.service
  --volume=/etc/kubernetes/volumeplugins:/etc/kubernetes/volumeplugins:rw \
        --volume-plugin-dir=/etc/kubernetes/volumeplugins \
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Note:
 - `/etc/kubernetes/volumeplugins` has already been the default flexvolume plugin directory in acs-engine (starting from v0.12.0)
 - There would be one line of [kubelet log](https://github.com/andyzhangx/Demo/tree/master/debug#q-how-to-get-k8s-kubelet-logs-on-linux-agent) in agent node like below showing that `flexvolume-azure/blobfuse` is loaded correctly
```
I0122 08:24:47.761479    2963 plugins.go:469] Loaded volume plugin "flexvolume-azure/blobfuse"
```
 - Flexvolume is GA from Kubernetes **1.8** release, v1.7 is depreciated since it does not support flex volume driver dynamic detection.
 
## 2. install blobfuse flex volume driver on every agent node
### Option#1. Automatically install by k8s daemonset
create daemonset to install blobfuse driver
 - v1.9
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.9.yaml
```
 - v1.8
```
 kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.8.yaml
```
 - check daemonset status:
```
kubectl describe daemonset blobfuse-flexvol-installer --namespace=kube-system
kubectl get po --namespace=kube-system
```

### Option#2. Manually install on every agent node (depreciated)
Take k8s v1.9 as an example:
```
version=v1.9
sudo mkdir -p /etc/kubernetes/volumeplugins/azure~blobfuse/bin
cd /etc/kubernetes/volumeplugins/azure~blobfuse/bin

sudo wget -O blobfuse https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/binary/hyperkube-$version/v0.2.4/blobfuse
sudo chmod a+x blobfuse

cd /etc/kubernetes/volumeplugins/azure~blobfuse
sudo wget -O blobfuse https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/blobfuse
sudo chmod a+x blobfuse
```

# Basic Usage
## 1. create a secret which stores blobfuse account name and password
```
kubectl create secret generic blobfusecreds --from-literal username=USERNAME --from-literal password="PASSWORD" --type="azure/blobfuse"
```
> Note
If secret type is not set correctly as driver name `azure/blobfuse`, you will get following error:
```
MountVolume.SetUp failed for volume "azure" : Couldn't get secret default/azure-secret
```

## 2. create a pod with blobfuse flexvolume mount on linux
#### Option#1 Use flexvolume mount directly inside a pod
- download `nginx-flex-blobfuse.yaml` file and modify `container` field
```
wget -O nginx-flex-blobfuse.yaml https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/nginx-flex-blobfuse.yaml
vi nginx-flex-blobfuse.yaml
```
 - create a pod with blobfuse flexvolume driver mount
```
kubectl create -f nginx-flex-blobfuse.yaml
```

#### Option#2 Create blobfuse flexvolume PV & PVC and then create a pod based on PVC
 - download `pv-blobfuse-flexvol.yaml` file, modify `container` field and create a blobfuse flexvolume persistent volume(PV)
```
wget https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/pv-blobfuse-flexvol.yaml
vi pv-blobfuse-flexvol.yaml
kubectl create -f pv-blobfuse-flexvol.yaml
```

 - create a blobfuse flexvolume persistent volume claim(PVC)
```
 kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/pvc-blobfuse-flexvol.yaml
```
 
 - create a pod with blobfuse flexvolume PVC
```
 kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/nginx-flex-blobfuse-pvc.yaml
 ```

#### watch the status of pod until its Status changed from `Pending` to `Running`
watch kubectl describe po nginx-flex-blobfuse

## 3. enter the pod container to do validation
kubectl exec -it nginx-flex-blobfuse -- bash

```
root@nginx-flex-blobfuse:/# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay          30G  5.5G   24G  19% /
tmpfs           3.4G     0  3.4G   0% /dev
tmpfs           3.4G     0  3.4G   0% /sys/fs/cgroup
blobfuse         30G  5.5G   24G  19% /data
/dev/sda1        30G  5.5G   24G  19% /etc/hosts
shm              64M     0   64M   0% /dev/shm
tmpfs           3.4G   12K  3.4G   1% /run/secrets/kubernetes.io/serviceaccount
```
In the above example, there is a `/data` directory mounted as blobfuse filesystem.

### Links
[azure-storage-fuse](https://github.com/Azure/azure-storage-fuse)

[Flexvolume doc](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md)

More clear steps about flexvolume by Redhat doc: [Persistent Storage Using FlexVolume Plug-ins](https://docs.openshift.org/latest/install_config/persistent_storage/persistent_storage_flex_volume.html)
