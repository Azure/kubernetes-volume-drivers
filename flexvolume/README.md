# kubernetes FlexVolume driver on Azure
This directory contains all kubernetes [FlexVolume](https://kubernetes.io/docs/concepts/storage/volumes/#flexvolume) drivers on azure

| FlexVolume driver | About |
| ---- | ---- |
| [blobfuse](./blobfuse) | This driver allows Kubernetes to access virtual filesystem backed by the Azure Blob storage. |
| [cifs](./cifs) | This driver allows Kubernetes to access SMB server by using CIFS/SMB protocol. |
| [dysk](./dysk) | This driver allows Kubernetes to use [fast kernel-mode mount/unmount AzureDisk](https://github.com/khenidak/dysk) |
