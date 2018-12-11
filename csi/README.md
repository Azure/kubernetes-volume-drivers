# kubernetes CSI driver on Azure
This directory contains all kubernetes [CSI](https://kubernetes-csi.github.io/docs/Home.html) drivers on azure

| CSI driver | About |
| ---- | ---- |
| [azurefile](./azurefile) | This driver allows Kubernetes to use [azure file](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-introduction) volume |
| [dysk](./dysk) | This driver allows Kubernetes to use [fast kernel-mode mount/unmount AzureDisk](https://github.com/khenidak/dysk) |
| [hostpath](./hostpath) | This driver allows Kubernetes to use hostPath |
