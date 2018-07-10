## 1. Build blobfuse-flexvol-installer image

```
cd blobfuse-flexvol-installer

docker build --no-cache -t andyzhangx/blobfuse-flexvol-installer:1.0.6 .
```
## 2. Test blobfuse-flexvol-installer image
```
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex andyzhangx/blobfuse-flexvol-installer:1.0.6
vi /tmp/volumeplugins/azure~blobfuse/blobfuse
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
docker push andyzhangx/blobfuse-flexvol-installer:1.0.6
```

### `blobfuse-flexvol-installer` image release notes
| `blobfuse-flexvol-installer` image version | blobfuse binary version | release notes |
| ---- | ---- | ---- |
| 1.0.0 | 0.2.4 | 1st version  |
| 1.0.1 | 0.3.1 |  upgrade blobfuse binary |
| 1.0.2 | 0.3.1 |  use accountname & accountkey in blobfuse driver |
| 1.0.3 | 1.0.0-RC |  1. upgrade blobfuse binary 2. retuen error if accountname or accountkey is empty|
| 1.0.4 | 1.0.0-RC |  add readOnly support|
| 1.0.5 | N/A | support kubelet running outside of container; support `tmp-path` parameter|
| 1.0.6 | N/A | support user specified `mountoptions` parameter|
