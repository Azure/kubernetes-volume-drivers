### install blobfuse driver on kubernetes version v1.8 & v1.7
```
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer-1.8.yaml
```
> Note: for deployment on v1.7, it requires restarting kubelet on every node(`sudo systemctl restart kubelet`) after daemonset running complete due to [Dynamic Plugin Discovery](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md#dynamic-plugin-discovery) not supported on k8s v1.7

### install blobfuse driver on kubernetes manually
### 1) install blobfuse on every agent node
Please refer to [Install from Apt/Yum Package Repositories](https://github.com/Azure/azure-storage-fuse/wiki/1.-Installation#option-1---install-from-aptyum-package-repositories)
 > Note: on a k8s cluster set up by AKS or acs-engine blobfuse(`1.0.2`) is already installed.

### 2) install `jq` package on every agent node
> Note: skip this step in [AKS](https://azure.microsoft.com/en-us/services/container-service/) or from [acs-engine](https://github.com/Azure/acs-engine) v0.16.0
```
sudo apt install jq -y
```

### 3) install blobfuse FlexVolume driver on every agent node
```
sudo mkdir -p /etc/kubernetes/volumeplugins/azure~blobfuse

cd /etc/kubernetes/volumeplugins/azure~blobfuse
sudo wget -O blobfuse https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/blobfuse
sudo chmod a+x blobfuse
```
