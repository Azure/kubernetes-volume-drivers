# kubernetes FlexVolume driver on Azure
This directory contains all kubernetes [FlexVolume](https://kubernetes.io/docs/concepts/storage/volumes/#flexvolume) drivers on azure:

| FlexVolume driver | About |
| ---- | ---- |
| [blobfuse](./blobfuse) | This driver allows Kubernetes to access virtual filesystem backed by the Azure Blob storage. |
| [cifs](./cifs) | This driver allows Kubernetes to access SMB server by using CIFS/SMB protocol. |
| [dysk](./dysk) | This driver allows Kubernetes to use [fast kernel-mode mount/unmount AzureDisk](https://github.com/khenidak/dysk) |

## config kubelet service to enable FlexVolume driver
> Note: skip this step in [AKS](https://azure.microsoft.com/en-us/services/container-service/) or from [acs-engine](https://github.com/Azure/acs-engine) v0.12.0
 - specify `volume-plugin-dir` in kubelet service config

append following two lines **seperately** into `/etc/systemd/system/kubelet.service` file
```
  --volume=/etc/kubernetes/volumeplugins:/etc/kubernetes/volumeplugins:rw \
        --volume-plugin-dir=/etc/kubernetes/volumeplugins \
```

```
sudo vi /etc/systemd/system/kubelet.service
...
ExecStart=/usr/bin/docker run \
  --net=host \
  ...
  --volume=/etc/kubernetes/volumeplugins:/etc/kubernetes/volumeplugins:rw \
    ${KUBELET_IMAGE} \
      /hyperkube kubelet \
        --require-kubeconfig \
        --v=2 \
	...
      --volume-plugin-dir=/etc/kubernetes/volumeplugins \
        $KUBELET_CONFIG $KUBELET_OPTS \
        ${KUBELET_REGISTER_NODE} ${KUBELET_REGISTER_WITH_TAINTS}
...

sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

Note:
 - `/etc/kubernetes/volumeplugins` has already been the default flexvolume plugin directory in acs-engine (starting from v0.12.0)
 - Flexvolume is GA from Kubernetes **1.8** release, v1.7 is depreciated since it does not support [Dynamic Plugin Discovery](https://github.com/kubernetes/community/blob/master/contributors/devel/flexvolume.md#dynamic-plugin-discovery).
