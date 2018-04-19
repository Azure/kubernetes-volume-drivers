## 1. Build blobfuse-flexvol-installer image

```
mkdir blobfuse-flexvol-installer
cd blobfuse-flexvol-installer

wget -O Dockerfile https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/Dockerfile
wget -O install.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/install.sh
wget -O download_blobfuse.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/download_blobfuse.sh
chmod a+x install.sh
chmod a+x download_blobfuse.sh

./download_blobfuse.sh
docker build --no-cache -t andyzhangx/blobfuse-flexvol-installer:1.0.2 .
```
## 2. Test blobfuse-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex andyzhangx/blobfuse-flexvol-installer:1.0.2
vi /tmp/volumeplugins/azure~blobfuse/blobfuse
ls -lt /tmp/volumeplugins/azure~blobfuse/bin
cat /var/log/blobfuse-flexvol-installer.log
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
docker push andyzhangx/blobfuse-flexvol-installer:1.0.2
```

### `blobfuse-flexvol-installer` image release notes
| `blobfuse-flexvol-installer` image version | blobfuse version | release notes |
| ---- | ---- | ---- |
| 1.0.0 | 0.2.4 | 1st version  |
| 1.0.1 | 0.3.1 |  upgrade blobfuse binary |
| 1.0.1 | 0.3.1 |  use accountname & accountkey in blobfuse driver |
