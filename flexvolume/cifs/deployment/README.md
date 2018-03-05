## 1. Build cifs-flexvol-installer image

```
mkdir cifs-flexvol-installer
cd cifs-flexvol-installer

wget -O Dockerfile https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/deployment/cifs-flexvol-installer/Dockerfile
wget -O install.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/deployment/cifs-flexvol-installer/install.sh
chmod a+x install.sh

docker build --no-cache -t andyzhangx/cifs-flexvol-installer:1.0 .
```
## 2. Test cifs-flexvol-installer image
```
docker run -d --name flex andyzhangx/cifs-flexvol-installer:1.0
docker exec -it flex bash
cd /etc/kubernetes/volumeplugins/azure~cifs
bin/cifs
docker stop flex && docker rm flex
```

#### Note
if you cannot `docker exec -it flex bash`, run followng command to check logs:
```
docker logs flex
```

## 3. Push cifs-flexvol-installer image
```
docker login
docker push andyzhangx/cifs-flexvol-installer:1.0
```
