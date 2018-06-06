## 1. Build dysk-flexvol-installer image

```
cd flexvol-installer
wget https://raw.githubusercontent.com/andyzhangx/demo/master/linux/flexvolume/dysk/dyskctl
chmod a+x dyskctl

docker build --no-cache -t andyzhangx/dysk-flexvol-installer:0.7 .
```
## 2. Test dysk-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex andyzhangx/dysk-flexvol-installer:0.7
vi /tmp/volumeplugins/azure~dysk/dysk
ls -lt /tmp/volumeplugins/azure~dysk/
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
docker push andyzhangx/dysk-flexvol-installer:0.7
```

## `dysk-flexvol-installer` image release notes
| `dysk-flexvol-installer` image version | release notes |
| ---- | ---- |
| 0.6 |  1st version(for containerized kubelet)  |
| 0.7 | for kubelet running outside of container |
