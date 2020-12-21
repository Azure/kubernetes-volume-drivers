# Kubernetes volume drivers on Azure
This repository lists all Kubernetes volume drivers on Azure:

| driver type | about |
| ---- | ---- |
| [CSI](./csi) | This directory contains all kubernetes [CSI](https://kubernetes-csi.github.io/docs/Home.html) drivers on Azure |
| [FlexVolume](./flexvolume) | This directory contains all kubernetes [FlexVolume](https://kubernetes.io/docs/concepts/storage/volumes/#flexvolume) drivers on Azure |
| [LocalVolume](./local) | This directory contains all kubernetes [Local Persistent Volume](https://kubernetes.io/docs/concepts/storage/volumes/#local) support on Azure |
| [NFS](./local) | This directory contains [NFS Server Provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs) support on Azure |

## Support

Please see our [support policy][support-policy].

# Contributing
This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

[support-policy]: Support.md
