## 1. Build smb-flexvol-installer image

```
REPO_NAME=<YOUR-REPO-NAME>
VER=1.0.5
cd smb-flexvol-installer

docker build --no-cache -t $REPO_NAME/smb-flexvol-installer:$VER .
```
## 2. Test smb-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex $REPO_NAME/smb-flexvol-installer:$VER
vi /tmp/volumeplugins/microsoft.com~smb/smb
cat /var/log/smb-flexvol-installer.log
docker stop flex && docker rm flex
```

#### Note
if you cannot `docker exec -it flex bash`, run followng command to check logs:
```
docker logs flex
```

## 3. Push smb-flexvol-installer image
```
docker login
docker tag $REPO_NAME/smb-flexvol-installer:$VER $REPO_NAME/smb-flexvol-installer:latest
docker push $REPO_NAME/smb-flexvol-installer:latest
```

### `smb-flexvol-installer` image release notes
| `smb-flexvol-installer` image version | release notes |
| ---- | ---- |
| 1.0.0 | 1st version  |
| 1.0.1 | change cifs name to smb |
| 1.0.2 | fix potential blank space issue in smb mountoptions |
| 1.0.3 | install `jq`, `cifs-utils` by smb-flexvolume image |
| 1.0.4 | [ignore `fsGroup` setting](https://github.com/Azure/kubernetes-volume-drivers/pull/84) |
| 1.0.5 | fix: use busybox:1.32.0 to prevent security vulnerability issue |
