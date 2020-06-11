# blobfuse FlexVolume driver for Kubernetes
 - supported Kubernetes version: v1.7.0 or above
 - supported agent OS: Linux

# About
This driver allows Kubernetes to access virtual filesystem backed by the Azure Blob storage.

 ### blobfuse flexvolume Parameters
Name | Meaning | Example | Mandatory 
--- | --- | --- | ---
container | identical to `container-name` in [blobfuse mount options](https://github.com/Azure/azure-storage-fuse#mount-options) | `test` | Yes
tmppath | identical to `tmp-path` in [blobfuse mount options](https://github.com/Azure/azure-storage-fuse#mount-options) | `/tmp/blobfuse` | No
driverpath | location of `blobfuse` binary | `/usr/bin/blobfuse` | No
mountoptions | other mount options | `--file-cache-timeout-in-seconds=120 --use-https=true` | No

 - `fsGroup` securityContext setting

Blobfuse driver does not honor `fsGroup` securityContext setting, instead user could use `-o gid=1000` in `mountoptions` to set ownership, example [pv-blobfuse-flexvol-gid.yaml](./pv-blobfuse-flexvol-gid.yaml), check https://github.com/Azure/azure-storage-fuse#mount-options for more mountoptions.

### Latest Container Image:
`mcr.microsoft.com/k8s/flexvolume/blobfuse-flexvolume:1.0.13`

# Prerequisite
 - An azure storage account and a container should be created in the same region with the kubernetes cluster and storage account name, account key, container name should be provided in below example.
 - Make sure [blobfuse driver](https://github.com/Azure/azure-storage-fuse) has already been installed on every agent node of Kubernetes cluster

# Install blobfuse FlexVolume driver on a kubernetes cluster
## 1. config kubelet service to enable FlexVolume driver
> Note: skip this step in [AKS](https://azure.microsoft.com/en-us/services/container-service/) and [aks-engine](https://github.com/Azure/aks-engine)

Please refer to [config kubelet service to enable FlexVolume driver](https://github.com/Azure/kubernetes-volume-drivers/blob/master/flexvolume/README.md#config-kubelet-service-to-enable-flexvolume-driver)

## 2. Install blobfuse driver on every agent VM
### Install by kubernetes daemonset
 - v1.9 or above
```
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.9.yaml
```

 - check daemonset status:
```
watch kubectl describe daemonset blobfuse-flexvol-installer --namespace=kube-system
watch kubectl get po --namespace=kube-system -o wide
```

> install blobfuse driver manually, follow step [here](https://github.com/Azure/kubernetes-volume-drivers/blob/master/flexvolume/blobfuse/install-blobfuse-manually.md)

# Basic Usage
## 1. create a secret which stores azure storage account
 - create a secret which stores azure storage account name and account key
```
kubectl create secret generic blobfusecreds --from-literal accountname=ACCOUNT-NAME --from-literal accountkey="ACCOUNT-KEY" --type="azure/blobfuse"
```
 - create a secret which stores azure storage account name and account SAS token
```
kubectl create secret generic blobfusecreds --from-literal accountname=ACCOUNT-NAME --from-literal accountsastoken="sastoken" --type="azure/blobfuse"
```

> Sovereign Cloud support, add `blobendpoint` parameter in above commands
```
kubectl create secret generic blobfusecreds --from-literal blobendpoint="<youraccountname>.blob.core.chinacloudapi.cn" ...
```
available sovereign cloud names(more details could be found [here](https://github.com/Azure/azure-storage-fuse/wiki/2.-Configuring-and-Running#sovereign-clouds)):
```
<youraccountname>.blob.core.usgovcloudapi.net
<youraccountname>.blob.core.chinacloudapi.cn
<youraccountname>.blob.core.cloudapi.de
```

## 2. create a pod with blobfuse flexvolume mount on linux
#### Option#1 Ties a flexvolume volume explicitly to a pod
- download `nginx-flex-blobfuse.yaml` file and modify `container`, `tmppath`(optional) field
```
wget -O nginx-flex-blobfuse.yaml https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/nginx-flex-blobfuse.yaml
vi nginx-flex-blobfuse.yaml
```
 - create a pod with blobfuse flexvolume driver mount
```
kubectl create -f nginx-flex-blobfuse.yaml
```

#### Option#2 Create blobfuse flexvolume PV & PVC and then create a pod based on PVC
 > Note: access modes of blobfuse PV supports ReadWriteOnce(RWO), ReadOnlyMany(ROX) and ReadWriteMany(RWX)
 - download `pv-blobfuse-flexvol.yaml` file, modify `container` field and create a blobfuse flexvolume persistent volume(PV)
```
wget https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/pv-blobfuse-flexvol.yaml
vi pv-blobfuse-flexvol.yaml
kubectl create -f pv-blobfuse-flexvol.yaml
```

 - create a blobfuse flexvolume persistent volume claim(PVC)
```
 kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/pvc-blobfuse-flexvol.yaml
```

 - check status of PV & PVC until its Status changed from `Pending` to `Bound`
 ```
 kubectl get pv
 kubectl get pvc
 ```
 
 - create a pod with blobfuse flexvolume PVC
```
 kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/nginx-flex-blobfuse-pvc.yaml
 ```

## 3. enter the pod container to do validation
 - watch the status of pod until its Status changed from `Pending` to `Running`
```
watch kubectl describe po nginx-flex-blobfuse
```
 - enter the pod container
```
kubectl exec -it nginx-flex-blobfuse -- bash
root@nginx-flex-blobfuse:/# df -h
Filesystem      Size  Used Avail Use% Mounted on
overlay          30G  5.5G   24G  19% /
tmpfs           3.4G     0  3.4G   0% /dev
tmpfs           3.4G     0  3.4G   0% /sys/fs/cgroup
blobfuse         30G  5.5G   24G  19% /data
...
```
In the above example, there is a `/data` directory mounted as blobfuse filesystem.

### Tips
#### How to use flexvolume driver in Helm
Since flexvolume does not support dynamic provisioning, storageClass should be set as empty in Helm chart, take [wordpress](https://github.com/kubernetes/charts/tree/master/stable/wordpress) as an example:
 - Set up a blobfuse flexvolume PV and also `blobfusecreds` first
```
kubectl create secret generic blobfusecreds --from-literal accountname=ACCOUNT-NAME --from-literal accountkey="ACCOUNT-KEY" --type="azure/blobfuse"
kubectl create -f pv-blobfuse-flexvol.yaml
```
 - Specify `persistence.accessMode=ReadWriteMany,persistence.storageClass="-"` in [wordpress](https://github.com/kubernetes/charts/tree/master/stable/wordpress) chart
```
helm install --set persistence.accessMode=ReadWriteMany,persistence.storageClass="-" stable/wordpress
```

#### Troubleshooting
 - Check blobfuse flexvolume installation result on the node:
```
sudo cat /var/log/blobfuse-flexvol-installer.log
```
 - Get blobfuse driver version:
```
kubectl get po -n kube-system | grep blobfuse
kubectl describe po blobfuse-flexvol-installer-xxxxx -n kube-system | grep blobfuse-flexvolume
```
 - If there is pod mounting error like following:
```
MountVolume.SetUp failed for volume "test" : invalid character 'C' looking for beginning of value
```
Please attach log file `/var/log/blobfuse-driver.log` and file an issue

 > In most error cases, the failure is due to incorrect storage account name, key or container, follow below guide to check on agent node:
```
mkdir test
export AZURE_STORAGE_ACCOUNT=
export AZURE_STORAGE_ACCESS_KEY=
# only for sovereign cloud
# export AZURE_STORAGE_BLOB_ENDPOINT=<youraccountname>.blob.core.chinacloudapi.cn
blobfuse test --container-name=CONTAINER-NAME --tmp-path=/tmp/blobfuse -o allow_other --file-cache-timeout-in-seconds=120
```

### Links
 - [azure-storage-fuse](https://github.com/Azure/azure-storage-fuse)
 - [blobfuse CSI driver](https://github.com/csi-driver/blobfuse-csi-driver)
 - [Flexvolume doc](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md)
 - [Persistent Storage Using FlexVolume Plug-ins](https://docs.openshift.org/latest/install_config/persistent_storage/persistent_storage_flex_volume.html)
