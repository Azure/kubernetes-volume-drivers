# CIFS/SMB FlexVolume driver for Kubernetes
 - supported Kubernetes version: available from v1.7
 - supported agent OS: Linux 
 > For Windows support, refer to https://github.com/Microsoft/K8s-Storage-Plugins/tree/master/flexvolume/windows

# About
This driver allows Kubernetes to access SMB server by using [CIFS/SMB](https://en.wikipedia.org/wiki/Server_Message_Block) protocol.

### Latest Container Image:
`mcr.microsoft.com/k8s/flexvolume/smb-flexvolume:1.0.2`

# Consider using the Helm chart for an all-in-one install

See `./helm/README.md` for instructions on deploying an SMB share to your Kubernetes cluster using Helm.
The Helm chart compresses the steps below, including installing jq and cifs-utils on each cluster node,
into one config file (`./helm/smb-flexvol/values.yaml`) and one deployment step. 

# Prerequisite
Make sure `jq`, `cifs-utils` packages have already been installed on every agent node of Kubernetes cluster
> these packages have already been installed in Kubernetes cluster created by [AKS](https://azure.microsoft.com/en-us/services/container-service/) or [aks-engine](https://github.com/Azure/aks-engine).

# Install smb FlexVolume driver on a kubernetes cluster
## 1. config kubelet service to enable FlexVolume driver
> Note: skip this step in [AKS](https://azure.microsoft.com/en-us/services/container-service/) and [aks-engine](https://github.com/Azure/aks-engine)

Please refer to [config kubelet service to enable FlexVolume driver](https://github.com/Azure/kubernetes-volume-drivers/blob/master/flexvolume/README.md#config-kubelet-service-to-enable-flexvolume-driver)
 
## 2. install smb FlexVolume driver on every agent VM
 > Note: You may replace `/etc/kubernetes/volumeplugins` with `/usr/libexec/kubernetes/kubelet-plugins/volume/exec/`(by default) in `install-smb-flexvol-ubuntu.sh` if it's not a Kubernetes cluster created by [AKS](https://azure.microsoft.com/en-us/services/container-service/) or [aks-engine](https://github.com/Azure/aks-engine)
### Option#1. Automatically install by k8s daemonset
create daemonset to install smb driver
```
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/smb/deployment/smb-flexvol-installer.yaml
```
 - check daemonset status:
```
watch kubectl describe daemonset smb-flexvol-installer --namespace=kube-system
watch kubectl get po --namespace=kube-system -o wide
```
> Note: for deployment on v1.7, it requires restarting kubelet on every node(`sudo systemctl restart kubelet`) after daemonset running complete due to [Dynamic Plugin Discovery](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md#dynamic-plugin-discovery) not supported on k8s v1.7

### Option#2. install smb FlexVolume driver manually
 - run following command on every agent node
 > Note: below script only applies to Ubuntu
```
curl -skSL https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/smb/deployment/install-smb-flexvol-ubuntu.sh | sh -s --
```

# Basic Usage
## 1. create a secret which stores smb account name and password
```
kubectl create secret generic smbcreds --from-literal username=USERNAME --from-literal password="PASSWORD" --type="microsoft.com/smb"
```
> append `\` before special characters(e.g. `$!`), if `echo` command works well, then password could be parsed in smb plugin, follow details [here](https://github.com/Azure/kubernetes-volume-drivers/issues/34#issuecomment-528722899)

## 2. create a pod with smb flexvolume mount on linux
#### Option#1 Ties a flexvolume volume explicitly to a pod
- download `nginx-flex-smb.yaml` file and modify `source` field
```
wget -O nginx-flex-smb.yaml https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/smb/nginx-flex-smb.yaml
vi nginx-flex-smb.yaml
```
 - create a pod with smb flexvolume driver mount
```
kubectl create -f nginx-flex-smb.yaml
```

#### Option#2 Create smb flexvolume PV & PVC and then create a pod based on PVC
 > Note: access modes of smb PV supports ReadWriteOnce(RWO), ReadOnlyMany(ROX) and ReadWriteMany(RWX)
 - download `pv-smb-flexvol.yaml` file, modify `source` field and create a smb flexvolume persistent volume(PV)
```
wget https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/smb/pv-smb-flexvol.yaml
vi pv-smb-flexvol.yaml
kubectl create -f pv-smb-flexvol.yaml
```

 - create a smb flexvolume persistent volume claim(PVC)
```
 kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/smb/pvc-smb-flexvol.yaml
```

 - check status of PV & PVC until its Status changed from `Pending` to `Bound`
 ```
 kubectl get pv
 kubectl get pvc
 ```
 
 - create a pod with smb flexvolume PVC
```
 kubectl create -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/smb/nginx-flex-smb-pvc.yaml
 ```

## 3. enter the pod container to do validation
 - watch the status of pod until its Status changed from `Pending` to `Running`
```
watch kubectl describe po nginx-flex-smb
```
 - enter the pod container
```
kubectl exec -it nginx-flex-smb -- bash
```

```
root@nginx-flex-smb:/# df -h
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
In the above example, there is a `/data` directory mounted as smb filesystem.

### smb flexvolume Parameters
Name | Meaning | Example | Mandatory 
--- | --- | --- | ---
source | smb server address | `//STORAGE-ACCOUNT.file.core.windows.net/SHARE-NAME` for auzre file format | Yes
mountoptions | mount options | `vers=3.0,dir_mode=0777,file_mode=0777` | No

#### Debugging skills
 - Check smb flexvolume installation result on the node:
```
sudo cat /var/log/smb-flexvol-installer.log
```
 - Get smb driver version:
```
kubectl get po -n kube-system | grep smb
kubectl describe po smb-flexvol-installer-xxxxx -n kube-system | grep smb-flexvolume
```
 - If there is pod mounting error like following:
```
MountVolume.SetUp failed for volume "test" : invalid character 'C' looking for beginning of value
```
Please attach log file `/var/log/smb-driver.log` and file an issue

### Links
[CIFS/SMB wiki](https://en.wikipedia.org/wiki/Server_Message_Block)

[Flexvolume doc](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md)

[Persistent Storage Using FlexVolume Plug-ins](https://docs.openshift.org/latest/install_config/persistent_storage/persistent_storage_flex_volume.html)

### Developer Tip for working on Helm Chart + Docker FlexVol-Installer 

Skaffold can make it easier to iteratively debug the helm chart / docker installer. See `./skaffold.yaml` for details.