## 1. Build blobfuse-flexvol-installer image

```
mkdir blobfuse-flexvol-installer
cd blobfuse-flexvol-installer

wget -O Dockerfile https://github.com/andyzhangx/kubernetes-drivers-azure/blob/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/Dockerfile
wget -O install.sh https://github.com/andyzhangx/kubernetes-drivers-azure/blob/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/install.sh
chmod a+x install.sh

docker build --no-cache -t andyzhangx/blobfuse-flexvol-installer:1.0 .
```
## 2. Test blobfuse-flexvol-installer image
```
docker run -d --name flex andyzhangx/blobfuse-flexvol-installer:1.0
docker exec -it flex bash
cd /etc/kubernetes/volumeplugins/azure~blobfuse
bin/blobfuse
docker stop flex && docker rm flex
```

#### Note
if you cannot `docker exec -it flex bash`, run followng command to check logs:
```
docker logs flex
```

## 3. Push blobfuse-flexvol-installer image
```
docker login
docker push andyzhangx/blobfuse-flexvol-installer:1.0
```
