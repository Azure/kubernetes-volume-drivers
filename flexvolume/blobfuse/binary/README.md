## How to build blobfuse binary for FlexVolume dirver running in kubelet
```
VER=v1.9.0
docker run --name hyperkube -v /var/log:/var/log -it gcrio.azureedge.net/google_containers/hyperkube-amd64:$VER bash
apt-get update
apt-get install pkg-config libfuse-dev cmake libcurl4-gnutls-dev libgnutls28-dev libgcrypt20-dev -y
apt-get install g++ -y
git clone https://github.com/azure/azure-storage-fuse
cd azure-storage-fuse
git checkout v0.3.1
./build.sh

build/blobfuse
cp build/blobfuse /var/log/
```

## Validate blobfuse binary for FlexVolume dirver running in kubelet
```
VER=v1.9.0
docker run --name hyperkube -v /var/log:/var/log -it gcrio.azureedge.net/google_containers/hyperkube-amd64:$VER bash
apt-get update && apt-get install wget -y
wget -O blobfuse https://raw.githubusercontent.com/andyzhangx/Demo/master/linux/flexvolume/blobfuse/binary/kubelet/v1.9/blobfuse
chmod a+x blobfuse
./blobfuse
```
