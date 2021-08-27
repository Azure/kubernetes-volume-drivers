# Use Rook Ceph on Azure Kubernetes Service

[Rook](https://github.com/rook/rook) is an open source cloud-native storage orchestrator for Kubernetes.
It turns existing storage software into self-managing, self-scaling, and self-healing storage services that run seamlessly on-top of Kubernetes.
It is a [CNCF graduated](https://www.cncf.io/projects/) project.

[Ceph](https://ceph.com/en/) is a highly scalable distributed storage solution for block storage, object storage, and shared filesystems with years of production deployments.

This article shows you how to deploy Rook Ceph on Azure Kubernetes Service (AKS) and use it as the storage solution for your cluster.

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

To isolate storage from your applications, create a dedicated node pool for Rook Ceph.

```bash
az aks nodepool add -g ${RESOURCE_GROUP} --cluster-name ${CLUSTER} --name storagepool --node-count 3 --node-taints storage-node=true:NoSchedule --labels storage-node=true
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
aks-nodepool1-14514606-vmss000000      Ready    agent   20m   v1.20.7
aks-nodepool1-14514606-vmss000001      Ready    agent   20m   v1.20.7
aks-nodepool1-14514606-vmss000002      Ready    agent   20m   v1.20.7
aks-storagepool-14514606-vmss000000    Ready    agent   94s   v1.20.7
aks-storagepool-14514606-vmss000001    Ready    agent   74s   v1.20.7
aks-storagepool-14514606-vmss000002    Ready    agent   93s   v1.20.7
```

## Step 2: Deploy Rook Ceph

### Step 2.1: Clone this repo

```bash
git clone https://github.com/Azure/kubernetes-volume-drivers
cd kubernetes-volume-drivers/rook-ceph/
```

### Step 2.2: Deploy Rook Operator

Run the following commands to deploy Rook operator.

```bash
# Create common resources.
kubectl create -f https://raw.githubusercontent.com/rook/rook/v1.7.1/cluster/examples/kubernetes/ceph/crds.yaml
kubectl create -f https://raw.githubusercontent.com/rook/rook/v1.7.1/cluster/examples/kubernetes/ceph/common.yaml

# Create operator.
kubectl create -f examples/operator.yaml
```

Verify the rook-ceph-operator is in the `Running` state before proceeding.

```bash
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName -n rook-ceph
```

Expected output:
```
NAME                                  STATUS    NODE
rook-ceph-operator-6d479fd6cb-csnm5   Running   aks-storagepool2-14514606-vmss000000
```

References:
* [Deploy the Rook Operator](https://rook.io/docs/rook/v1.7/ceph-quickstart.html#deploy-the-rook-operator)

### Step 2.3: Create Rook Ceph cluster

Create a Rook Ceph cluster.

```bash
kubectl create -f examples/cluster-on-pvc.yaml
```

Verify PVCs are created as expected:
* rook-ceph-mon-* are used by MON. They are used to store critical data by MON.
* set1-data-* are used by OSD. They will be used by your storage clients later.

```bash
kubectl get pvc -n rook-ceph
```

Expected output:
```
NAME               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
rook-ceph-mon-a    Bound    pvc-b6a81925-2427-4ea6-ae37-3908a55b6941   10Gi       RWO            managed-premium   15h
rook-ceph-mon-b    Bound    pvc-e516ca8e-9342-4766-88b3-f3024b9e0d7b   10Gi       RWO            managed-premium   15h
rook-ceph-mon-c    Bound    pvc-7748269e-0d19-49fb-a8f5-9dd25b6f1198   10Gi       RWO            managed-premium   15h
set1-data-0nx28h   Bound    pvc-e6541362-e450-492e-a195-215f40120c05   10Gi       RWO            default           15h
set1-data-1wkr2h   Bound    pvc-f47d6fbe-1670-4c6c-8114-b6d8a4bb48f0   10Gi       RWO            default           15h
set1-data-2v8957   Bound    pvc-abf7095a-836f-4a0d-94fa-3f5cc6951059   10Gi       RWO            default           15h
```

Verify the components are running as expected:
* Plugins running on non-storage nodes.
* Provisioner, crashcollector, MGR, MON, OSD, and operator running on storage nodes.

```
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName -n rook-ceph
```

Expected output:
```
NAME                                                              STATUS      NODE
csi-cephfsplugin-7n86j                                            Running     aks-nodepool1-14514606-vmss000000
csi-cephfsplugin-cgsg9                                            Running     aks-nodepool1-14514606-vmss000001
csi-cephfsplugin-drxj4                                            Running     aks-nodepool1-14514606-vmss000002
csi-cephfsplugin-provisioner-84d8b944d7-5dpr6                     Running     aks-storagepool2-14514606-vmss000002
csi-cephfsplugin-provisioner-84d8b944d7-hqvlh                     Running     aks-storagepool2-14514606-vmss000000
csi-rbdplugin-842wn                                               Running     aks-nodepool1-14514606-vmss000002
csi-rbdplugin-9lblk                                               Running     aks-nodepool1-14514606-vmss000000
csi-rbdplugin-provisioner-657f68b894-lffhs                        Running     aks-storagepool2-14514606-vmss000001
csi-rbdplugin-provisioner-657f68b894-ndvxq                        Running     aks-storagepool2-14514606-vmss000002
csi-rbdplugin-s9fsp                                               Running     aks-nodepool1-14514606-vmss000001
rook-ceph-crashcollector-aks-storagepool2-14514606-vmss0009nfwm   Running     aks-storagepool2-14514606-vmss000000
rook-ceph-crashcollector-aks-storagepool2-14514606-vmss000lkw7w   Running     aks-storagepool2-14514606-vmss000002
rook-ceph-crashcollector-aks-storagepool2-14514606-vmss000qg7s4   Running     aks-storagepool2-14514606-vmss000001
rook-ceph-mgr-a-57f7b95d5f-7hxnr                                  Running     aks-storagepool2-14514606-vmss000001
rook-ceph-mon-a-68b68cd995-v9bpp                                  Running     aks-storagepool2-14514606-vmss000002
rook-ceph-mon-b-68f9787bfb-tklhk                                  Running     aks-storagepool2-14514606-vmss000001
rook-ceph-mon-c-b4d75868c-5gn9v                                   Running     aks-storagepool2-14514606-vmss000000
rook-ceph-operator-6d479fd6cb-csnm5                               Running     aks-storagepool2-14514606-vmss000000
rook-ceph-osd-0-568bf5957c-dc796                                  Running     aks-storagepool2-14514606-vmss000000
rook-ceph-osd-1-559dbc87f7-sg2q2                                  Running     aks-storagepool2-14514606-vmss000001
rook-ceph-osd-2-f5c5d97c7-bn84k                                   Running     aks-storagepool2-14514606-vmss000002
rook-ceph-osd-prepare-set1-data-0nx28h-f2hh7                      Succeeded   aks-storagepool2-14514606-vmss000001
rook-ceph-osd-prepare-set1-data-1wkr2h-6g29v                      Succeeded   aks-storagepool2-14514606-vmss000001
rook-ceph-osd-prepare-set1-data-2v8957-qxfpg                      Succeeded   aks-storagepool2-14514606-vmss000001
```

References:
* [Create a Rook Ceph Cluster](https://rook.io/docs/rook/v1.7/ceph-quickstart.html#create-a-rook-ceph-cluster)

### (Optional) Step 2.4: Set up and use Ceph Dashboard

The dashboard gives an overview of the status of your Ceph cluster, including overall health, status of various components, logs, and more.

![alt text](https://rook.io/docs/rook/v1.7/media/ceph-dashboard.png)

Expose Ceph dashboard externally:

```bash
kubectl create -f https://raw.githubusercontent.com/rook/rook/v1.7.1/cluster/examples/kubernetes/ceph/dashboard-loadbalancer.yaml
```

Get URL, user name, and password to access the dashboard:

```bash
EXTERNAL_IP=$(kubectl get service -n rook-ceph rook-ceph-mgr-dashboard-loadbalancer --output jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "URL: https://${EXTERNAL_IP}:8443"

kubectl get service rook-ceph-mgr-dashboard-loadbalancer -n rook-ceph
PASSWORD=$(kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo)
echo "User name: admin"
echo "Password: ${PASSWORD}"
```

Access the URL using a browser and use the user name and password to log in.

NOTE: If you encounter NET::ERR_CERT_INVALID using Chrome and would like to proceed anyway, click anywhere on the background and type `thisisunsafe`.

References:
* [Ceph Dashboard](https://rook.io/docs/rook/v1.7/ceph-dashboard.html)

### Step 2.5: Set up filesystem and storage class

Rook Ceph provides three types of storage: block storage, shared filesystem, and object storage. This section contains the instructions on how to set up a filesystem to be shared across multiple pods. See [block storage](https://rook.io/docs/rook/v1.7/ceph-block.html) or [object storage](https://rook.io/docs/rook/v1.7/ceph-object.html) on how to set up the other storage types.

Create filesystem:
```bash
kubectl create -f examples/filesystem.yaml

# Wait for running.
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName -n rook-ceph -l app=rook-ceph-mds
```

Expected output:
```
NAME                                    STATUS    NODE
rook-ceph-mds-myfs-a-66c86f4479-f87rg   Running   aks-storagepool2-14514606-vmss000000
rook-ceph-mds-myfs-b-58bbb59b5-lrjjj    Running   aks-storagepool2-14514606-vmss000001
```

Create storage class `rook-cephfs`:
```
kubectl apply -f https://raw.githubusercontent.com/rook/rook/v1.7.1/cluster/examples/kubernetes/ceph/csi/cephfs/storageclass.yaml

# Verify storage class.
kubectl get sc
```

Expected output:
```
NAME                PROVISIONER                     RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
rook-cephfs         rook-ceph.cephfs.csi.ceph.com   Delete          Immediate              true                   102s
```

References:
* [Shared Filesystem](https://rook.io/docs/rook/v1.7/ceph-filesystem.html)

## Step 3: Use and test filesystem

Now you can use storage class `rook-cephfs` in your applications to provision persistent volumes. This section contains a simple example of using `rook-cephfs` in a Nginx pod, and testing storage performance using various tools.

### Step 3.1: Use filesystem via a simple `nginx` pod

Create a pod running `nginx` with a 5GB PV mounted to /mnt/rook-cephfs.

```
kubectl apply -f examples/nginx.yaml

# Wait for running.
kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

Expected output:
```
NAME    STATUS    NODE
nginx   Running   aks-nodepool1-14514606-vmss000000
```

The following three sectinos provide three test suites. Each can be run independently of others.

### (Optional) Step 3.2: Test write bandwidth using `dd`

The following tests measure write bandwidth using `dd`.

#### Before you begin

Get a shell to the running pod:
```bash
kubectl -it exec pod/nginx -- bash
cd /mnt/rook-cephfs
```

#### Test scenario: Write a 2GB file

```bash
dd if=/dev/zero of=file1 bs=8k count=250000 && sync
```

Test output: Write bandwidth is 43.8 MB/s.
```
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 46.787 s, 43.8 MB/s
```

#### Test scenario: Copy a 2GB file

```bash
dd if=file1 of=file2 bs=8k count=250000 && sync
```

Test output: Write bandwidth is 41.3 MB/s.
```
250000+0 records in
250000+0 records out
2048000000 bytes (2.0 GB, 1.9 GiB) copied, 49.5639 s, 41.3 MB/s
```

#### Clean up

```bash
rm file1 file2
```

### (Optional) Step 3.3: Test latency of creating/deleting many small files

The following test measures the latency to create and delete 50k small files.

#### Before you begin

Get a shell to the running pod and install wget:
```bash
kubectl -it exec pod/nginx -- bash
apt update && apt install wget

# Go to the mounted directory.
cd /mnt/rook-cephfs
```

#### Test scenario: Download a file and unzip to 50k small files

```bash
time ( wget -qO- https://wordpress.org/latest.tar.gz | tar xvz -C . 2>&1 > /dev/null )
```

Test output: Latency to write 50k small files is ~5.6s.

```
real	0m5.578s
user	0m0.539s
sys	0m0.525s
```

#### Test scenario: Delete 50k small files

```
time ( du wordpress/ | tail -1 && rm -rf wordpress )
```

Test output: Latency to delete 50k small files is ~14s.
```
52235	wordpress/

real	0m14.426s
user	0m0.031s
sys	0m0.159s
```

### (Optional) Step 3.4: Test read/write IOPS, bandwidth, and latency using `fio`

#### Before you begin

Get a shell to the running pod and install fio.
```bash
kubectl -it exec pod/nginx -- bash
apt update && apt install fio

# Go to the mounted directory.
cd /mnt/rook-cephfs
```

#### Test scenario: Random read/write IOPS with 4k block size

Test read IOPS:
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=read_iops --filename=fiotest --bs=4K --iodepth=64 --size=2G --readwrite=randread --time_based --ramp_time=2s --runtime=15s
```

Test output: Read IOPS is 13.8k.
```
  read: IOPS=15.4k, BW=60.0MiB/s (62.0MB/s)(902MiB/15015msec)
```

Test write IOPS:
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=write_iops --filename=fiotest --bs=4K --iodepth=64 --size=2G --readwrite=randwrite --time_based --ramp_time=2s --runtime=15s
```

Test output: Write IOPS is 547.
```
  write: IOPS=547, BW=2207KiB/s (2260kB/s)(32.7MiB/15190msec); 0 zone resets
```

#### Test scenario: Random read/write bandwidth with 128k block size

Test read bandwidth:
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=read_bw --filename=fiotest --bs=128K --iodepth=64 --size=2G --readwrite=randread --time_based --ramp_time=2s --runtime=15s
```

Test output: Read bandwidth is 199MiB/s.
```
  read: IOPS=1586, BW=199MiB/s (208MB/s)(2988MiB/15032msec)
```

Test write bandwidth:
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=write_bw --filename=fiotest --bs=128K --iodepth=64 --size=2G --readwrite=randwrite --time_based --ramp_time=2s --runtime=15s
```

Test output: Write bandwidth is 159MiB/s.
```
  write: IOPS=1264, BW=159MiB/s (166MB/s)(2379MiB/15006msec); 0 zone resets
```

#### Test scenario: Random read/write latency with 4k block size

Test read latency:
```bash
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --name=read_latency --filename=fiotest --bs=4K --iodepth=4 --size=2G --readwrite=randread --time_based --ramp_time=2s --runtime=15s
```

Test output: Average read latency is ~0.7ms.
```
  read: IOPS=5511, BW=21.5MiB/s (22.6MB/s)(323MiB/15001msec)
    slat (nsec): min=0, max=4810.4k, avg=13008.19, stdev=23162.39
    clat (nsec): min=0, max=37612k, avg=710947.67, stdev=825552.92
     lat (nsec): min=0, max=37628k, avg=724128.66, stdev=826081.33
```

Test write latency:
```
fio --randrepeat=0 --verify=0 --ioengine=libaio --direct=1 --name=write_latency --filename=fiotest --bs=4K --iodepth=4 --size=2G --readwrite=randwrite --time_based --ramp_time=2s --runtime=15s
```

Test output: Average write latency is ~16ms.
```
  write: IOPS=239, BW=958KiB/s (981kB/s)(14.0MiB/15012msec); 0 zone resets
    slat (nsec): min=0, max=2183.7k, avg=56498.91, stdev=50796.48
    clat (nsec): min=0, max=119744k, avg=16652228.44, stdev=20419258.87
     lat (nsec): min=0, max=119783k, avg=16709246.27, stdev=20418470.89
```

#### Clean up

```bash
rm fiotest
```

### Step 3.5 Clean up

Delete the pod:
```bash
kubectl delete -f examples/nginx.yaml
```

### Step 4 Additional tooling and monitoring

To make Rook Ceph production ready, following these instructions to set up Rook Toolbox for debugging and testing, and Prometheus for monitoring and alerting.

* [Rook toolbox](https://rook.io/docs/rook/v1.7/ceph-toolbox.html)
* [Prometheus monitoring](https://rook.io/docs/rook/v1.7/ceph-monitoring.html)