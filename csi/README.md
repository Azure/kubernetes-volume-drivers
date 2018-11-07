# kubernetes CSI driver on Azure
This directory contains all kubernetes [CSI](https://kubernetes-csi.github.io/docs/Home.html) drivers on azure

## Note: CSI drivers in this repository only work before v1.12.0 since there is a CSI breaking change in v1.12.0, find details [here](https://github.com/Azure/kubernetes-volume-drivers/issues/8)

| CSI driver | About |
| ---- | ---- |
| [dysk](./dysk) | This driver allows Kubernetes to use [fast kernel-mode mount/unmount AzureDisk](https://github.com/khenidak/dysk) |
| [hostpath](./hostpath) | This driver allows Kubernetes to use hostPath |
