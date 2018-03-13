## 1. Build dysk-flexvol-installer image

```
mkdir dysk-flexvol-installer
cd dysk-flexvol-installer

wget -O Dockerfile https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/dysk/deployment/dysk-flexvol-installer/Dockerfile
wget -O install.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/dysk/deployment/dysk-flexvol-installer/install.sh
wget -O download_dysk.sh https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/dysk/deployment/dysk-flexvol-installer/download_dysk.sh
chmod a+x install.sh
chmod a+x download_dysk.sh

./download_dysk.sh
docker build --no-cache -t andyzhangx/dysk-flexvol-installer:1.0.0 .
```
## 2. Test dysk-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex andyzhangx/dysk-flexvol-installer:1.0.0
vi /tmp/volumeplugins/azure~dysk/dysk
ls -lt /tmp/volumeplugins/azure~dysk/bin
cat /var/log/dysk-flexvol-installer.log
docker stop flex && docker rm flex
```

#### Note
if you cannot `docker exec -it flex bash`, run followng command to check logs:
```
docker logs flex
```

## 3. Push dysk-flexvol-installer image
```
docker login
docker push andyzhangx/dysk-flexvol-installer:1.0.0
```
