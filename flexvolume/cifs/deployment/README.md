## 1. Build cifs-flexvol-installer image

```
mkdir cifs-flexvol-installer
cd cifs-flexvol-installer

wget -O Dockerfile https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/deployment/cifs-flexvol-installer/Dockerfile
wget -O install.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/deployment/cifs-flexvol-installer/install.sh
wget -O download_cifs.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/deployment/cifs-flexvol-installer/download_cifs.sh
chmod a+x install.sh
chmod a+x download_cifs.sh

./download_cifs.sh
docker build --no-cache -t andyzhangx/cifs-flexvol-installer:1.0 .
```
## 2. Test cifs-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex andyzhangx/cifs-flexvol-installer:1.0
vi /tmp/volumeplugins/azure~cifs/cifs
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
