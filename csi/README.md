# kubernetes CSI driver on Azure
This directory contains all kubernetes [CSI](https://kubernetes-csi.github.io/docs/Home.html) drivers on azure

| CSI driver | About |
| ---- | ---- |
| [Azure Disk](https://github.com/kubernetes-sigs/azuredisk-csi-driver) | This driver allows Kubernetes to use [Azure disk](https://azure.microsoft.com/en-us/services/storage/disks/) volume |
| [Azure File](https://github.com/kubernetes-sigs/azurefile-csi-driver) | This driver allows Kubernetes to use [Azure file](https://docs.microsoft.com/en-us/azure/storage/files/storage-files-introduction) volume |
| [Blob Storage](https://github.com/kubernetes-sigs/blob-csi-driver) | This driver allows Kubernetes to access Azure Storage through one of following methods:  <br> - [azure-storage-fuse](https://github.com/Azure/azure-storage-fuse) <br> - [NFSv3](https://docs.microsoft.com/en-us/azure/storage/blobs/network-file-system-protocol-support) |
| [hostpath](./hostpath) | This driver allows Kubernetes to use hostPath (experimental) |
