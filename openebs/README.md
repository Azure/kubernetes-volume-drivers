# Set up OpenEBS on Azure Kubernetes Service

OpenEBS is a "Container Attached Storage" or CAS solution which extends Kubernetes with a declarative data plane, providing flexible persistent storage for stateful applications.

[OpenEBS Mayastor](https://mayastor.gitbook.io/) incorporates Intel's Storage Performance Development Kit. It has been designed from the ground up to leverage the protocol and compute efficiency of NVMe-oF semantics, and the performance capabilities of the latest generation of solid-state storage devices, in order to deliver a storage abstraction with performance overhead measured to be within the range of single-digit percentages.

This article shows you how to deploy OpenEBS Mayastor on Azure Kubernetes Service (AKS) and uses it as the storage solution for your cluster.

## Before you begin

This article assumes that you have an existing Azure subscription and installed Azure CLI. If you haven't done so, see [how to install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

## Step 1: Create cluster and node pools

### Step 1.1: Create a new AKS cluster with a system node pool

To run production workloads, create a system node pool with at least 3 nodes.

```bash
# Create a resource group.
export RESOURCE_GROUP="${USER}ResourceGroup"
az group create --name ${RESOURCE_GROUP} --location eastus

# Create a cluster.
export CLUSTER="${USER}Cluster"
az aks create -g ${RESOURCE_GROUP} --name ${CLUSTER} --node-count 3 --generate-ssh-keys

# Get credentials for cluster access.
az aks get-credentials -g ${RESOURCE_GROUP} --name ${CLUSTER} --overwrite-existing
```

References:
* [Quickstart: Deploy an Azure Kubernetes Service cluster using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough)

### Step 1.2: Create a storage node pool
> Note: this is only for testing purposes. If you delete the VMSS instance, the data in the disk attached to the VMSS would be lost.
> 
To isolate storage from your applications, create a dedicated node pool for Mayastor.
 - create a node pool with 0 count first
```bash
az aks nodepool add -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER} --name storagepool --node-vm-size Standard_D4s_v3 --node-count 0  --labels openebs.io/engine=mayastor
```
 - attach 1TB data disk to every node of the dedicated node pool
> `NODE_RESOURCE_GROUP` is where all agent nodes are in Azure resources, it's usually starts with `MC_`
```bash
az vmss disk attach -g ${NODE_RESOURCE_GROUP} --vmss-name aks-small-15774340-vmss --size-gb 1024
```

 - scale up node pool count to 3 nodes
```bash
az aks nodepool scale -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER} --name storagepool -c 3
```

References:
* [Create and manage multiple node pools for a cluster in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/use-multiple-node-pools)

### Step 1.3: Verify

Verify that the nodes are in the `Ready` state before proceeding.

```bash
kubectl get nodes
```

Expected output:
```
NAME                                   STATUS   ROLES   AGE   VERSION
aks-nodepool1-14514606-vmss000000      Ready    agent   20m   v1.22.6
aks-nodepool1-14514606-vmss000001      Ready    agent   20m   v1.22.6
aks-nodepool1-14514606-vmss000002      Ready    agent   20m   v1.22.6
aks-storagepool-14514606-vmss000000    Ready    agent   94s   v1.22.6
aks-storagepool-14514606-vmss000001    Ready    agent   74s   v1.22.6
aks-storagepool-14514606-vmss000002    Ready    agent   93s   v1.22.6
```

## Step 2: Deploy OpenEBS Mayastor
### Step 2.1: Run a daemonset to configure Mayastor nodes
```bash
kubectl apply -f https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/openebs/init-openebs-env.yaml
```

### Step 2.2: Deploy OpenEBS Mayastor components
 - run following commands to deploy Mayastor components
> you could find all detailed steps [here](https://mayastor.gitbook.io/introduction/quickstart/deploy-mayastor)

```bash
kubectl create namespace mayastor
helm repo add mayastor https://openebs.github.io/mayastor-extensions/ 
helm search repo mayastor --versions
helm install mayastor mayastor/mayastor -n mayastor --create-namespace --version 2.1.0
kubectl get pods -n mayastor
```

### Step 2.3: Configure Mayastor
- configure DiskPool on dedicated node pool
> you could find all detailed steps [here](https://mayastor.gitbook.io/introduction/quickstart/configure-mayastor)

```bash
cat <<EOF | kubectl create -f -
apiVersion: "openebs.io/v1alpha1"
kind: DiskPool
metadata:
  name: pool-on-node-1
  namespace: mayastor
spec:
  node: aks-storagepool-14514606-vmss000000 
  disks: ["/dev/sdc"]
EOF
```

Verify Pool Creation and Status.

```bash
kubectl -n mayastor get dsp
```

Expected output:
```
NAME             NODE                                 STATE    POOL_STATUS   CAPACITY        USED           AVAILABLE
pool-on-node-0   aks-storagepool-14514606-vmss000000  Online   Online        1918504009728   0              1918504009728
```

### Step 2.4: Deploy a Test Application
 - follow this [guide](https://mayastor.gitbook.io/introduction/quickstart/deploy-a-test-application) to deploy a test application

<details> <summary> example pod events of volume attach  </summary> 

```
  Type    Reason                  Age   From                     Message
  ----    ------                  ----  ----                     -------
  Normal  Scheduled               16s   default-scheduler        Successfully assigned default/statefulset-azuredisk-maya-9 to aks-store-37972342-vmss000000
  Normal  SuccessfulAttachVolume  15s   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-2156ec5a-43e4-4b84-8f58-84b0de07cd1a"
  Normal  Pulled                  6s    kubelet                  Container image "mcr.microsoft.com/oss/nginx/nginx:1.19.5" already present on machine
  Normal  Created                 6s    kubelet                  Created container statefulset-azuredisk
  Normal  Started                 6s    kubelet                  Started container statefulset-azuredisk
 ```
 
 </details>
