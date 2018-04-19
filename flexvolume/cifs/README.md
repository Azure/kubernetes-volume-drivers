# CIFS/SMB FlexVolume driver for Kubernetes (Preview)
 - supported Kubernetes version: available from v1.7
 - supported agent OS: Linux 

# About
This driver allows Kubernetes to access SMB server by using [CIFS/SMB](https://en.wikipedia.org/wiki/Server_Message_Block) protocol.

# Install cifs FlexVolume driver on a kubernetes cluster
## 1. config kubelet service to enable FlexVolume driver
> Note: skip this step in [AKS](https://azure.microsoft.com/en-us/services/container-service/) or from [acs-engine](https://github.com/Azure/acs-engine) v0.12.0

Please refer to [config kubelet service to enable FlexVolume driver](https://github.com/andyzhangx/kubernetes-drivers/blob/master/flexvolume/README.md#config-kubelet-service-to-enable-flexvolume-driver)
 
## 2. install cifs FlexVolume driver on every agent node
### Option#1. Automatically install by k8s daemonset
create daemonset to install cifs driver
```
kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/deployment/cifs-flexvol-installer.yaml
```
 - check daemonset status:
```
watch kubectl describe daemonset cifs-flexvol-installer --namespace=flex
watch kubectl get po --namespace=flex -o wide
```
> Note: for deployment on v1.7, it requires restarting kubelet on every node(`sudo systemctl restart kubelet`) after daemonset running complete due to [Dynamic Plugin Discovery](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md#dynamic-plugin-discovery) not supported on k8s v1.7

### Option#2. Manually install on every agent node (depreciated)
```
sudo mkdir -p /etc/kubernetes/volumeplugins/azure~cifs/

cd /etc/kubernetes/volumeplugins/azure~cifs
sudo wget -O cifs https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/cifs
sudo chmod a+x cifs
```

# Basic Usage
## 1. create a secret which stores cifs account name and password
```
kubectl create secret generic cifscreds --from-literal username=USERNAME --from-literal password="PASSWORD" --type="azure/cifs"
```

## 2. create a pod with cifs flexvolume mount on linux
#### Option#1 Ties a flexvolume volume explicitly to a pod
- download `nginx-flex-cifs.yaml` file and modify `source` field
```
wget -O nginx-flex-cifs.yaml https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/nginx-flex-cifs.yaml
vi nginx-flex-cifs.yaml
```
 - create a pod with cifs flexvolume driver mount
```
kubectl create -f nginx-flex-cifs.yaml
```

#### Option#2 Create cifs flexvolume PV & PVC and then create a pod based on PVC
 > Note: access modes of cifs PV supports ReadWriteOnce(RWO), ReadOnlyMany(ROX) and ReadWriteMany(RWX)
 - download `pv-cifs-flexvol.yaml` file, modify `source` field and create a cifs flexvolume persistent volume(PV)
```
wget https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/pv-cifs-flexvol.yaml
vi pv-cifs-flexvol.yaml
kubectl create -f pv-cifs-flexvol.yaml
```

 - create a cifs flexvolume persistent volume claim(PVC)
```
 kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/pvc-cifs-flexvol.yaml
```

 - check status of PV & PVC until its Status changed from `Pending` to `Bound`
 ```
 kubectl get pv
 kubectl get pvc
 ```
 
 - create a pod with cifs flexvolume PVC
```
 kubectl create -f https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/nginx-flex-cifs-pvc.yaml
 ```

## 3. enter the pod container to do validation
 - watch the status of pod until its Status changed from `Pending` to `Running`
```
watch kubectl describe po nginx-flex-cifs
```
 - enter the pod container
```
kubectl exec -it nginx-flex-cifs -- bash
```

```
root@nginx-flex-cifs:/# df -h
Filesystem                                 Size  Used Avail Use% Mounted on
overlay                                    291G  3.2G  288G   2% /
tmpfs                                      3.4G     0  3.4G   0% /dev
tmpfs                                      3.4G     0  3.4G   0% /sys/fs/cgroup
//xiazhang3.file.core.windows.net/k8stest   25G   64K   25G   1% /data
/dev/sda1                                  291G  3.2G  288G   2% /etc/hosts
shm                                         64M     0   64M   0% /dev/shm
tmpfs                                      3.4G   12K  3.4G   1% /run/secrets/kubernetes.io/serviceaccount
tmpfs                                      3.4G     0  3.4G   0% /sys/firmware
```
In the above example, there is a `/data` directory mounted as cifs filesystem.

#### Debugging skills
 - If there is pod mounting error like following:
```
MountVolume.SetUp failed for volume "test" : invalid character 'C' looking for beginning of value
```
Please attach log file `/var/log/cifs-driver.log` and file an issue

### Links
[CIFS/SMB wiki](https://en.wikipedia.org/wiki/Server_Message_Block)

[Flexvolume doc](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md)

[Persistent Storage Using FlexVolume Plug-ins](https://docs.openshift.org/latest/install_config/persistent_storage/persistent_storage_flex_volume.html)
