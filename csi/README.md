# kubernetes CSI driver on Azure
This directory contains all kubernetes [CSI](https://kubernetes-csi.github.io/docs/Home.html) drivers on azure

| CSI driver | About |
| ---- | ---- |
| [azuredisk](https://github.com/kubernetes-sigs/azuredisk-csi-driver) | This driver allows Kubernetes to use [azure disk](https://azure.microsoft.com/en-us/services/storage/disks/) volume |
| [azurefile](https://github.com/kubernetes-sigs/azurefile-csi-driver) | This driver allows Kubernetes to use [azure file](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-introduction) volume |
| [blobfuse](https://github.com/kubernetes-sigs/blobfuse-csi-driver) | This driver allows Kubernetes to use [blobfuse](https://github.com/Azure/azure-storage-fuse) volume |
| [hostpath](./hostpath) | This driver allows Kubernetes to use hostPath (experimental) |
