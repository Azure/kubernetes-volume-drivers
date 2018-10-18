### Use [Azure Custom Script Extension](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-linux) to install blobfuse driver on every agent VM
 - use `az login` first and replace `RESOURCE_GROUP_NAME`, `VM_NAME` in following command for every agent VM
 > Note: for AKS cluster, all VM resources are under a shadow resource group naming as `MC_{RESOUCE-GROUP-NAME}{CLUSTER-NAME}{REGION}`; check `/var/lib/waagent/custom-script/download/1` directory if there is failure
```
az vm extension set \
  --resource-group RESOURCE_GROUP_NAME \
  --vm-name VM_NAME \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --protected-settings '{"fileUris": ["https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/install-blobfuse-flexvol-ubuntu.sh"],"commandToExecute": "./install-blobfuse-flexvol-ubuntu.sh"}'
```
 - Or log on every agent VM and run following command directly
 > Note: below script only applies to Ubuntu
```
curl -skSL https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/install-blobfuse-flexvol-ubuntu.sh | sh -s --
```
