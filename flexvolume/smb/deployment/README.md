## 1. Build smb-flexvol-installer image

```
cd smb-flexvol-installer

docker build --no-cache -t andyzhangx/smb-flexvol-installer:1.0.2 .
```
## 2. Test smb-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex andyzhangx/smb-flexvol-installer:1.0.2
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
docker push andyzhangx/smb-flexvol-installer:1.0.2
```

### `smb-flexvol-installer` image release notes
| `smb-flexvol-installer` image version | release notes |
| ---- | ---- |
| 1.0.0 | 1st version  |
| 1.0.1 | change cifs name to smb |
| 1.0.2 | fix potential blank space issue in smb mountoptions |
