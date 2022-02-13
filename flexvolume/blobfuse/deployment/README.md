## 1. Build blobfuse-flexvol-installer image
```console
REPO_NAME=<YOUR-REPO-NAME>
VER=1.0.18
cd blobfuse-flexvol-installer

docker build --no-cache -t $REPO_NAME/blobfuse-flexvol-installer:$VER .
```
## 2. Test blobfuse-flexvol-installer image
```console
docker run -d -v /tmp/volumeplugins/:/etc/kubernetes/volumeplugins/ -v /var/log:/var/log --name flex $REPO_NAME/blobfuse-flexvol-installer:$VER
vi /tmp/volumeplugins/azure~blobfuse/blobfuse
cat /var/log/blobfuse-flexvol-installer.log
docker stop flex && docker rm flex
```

#### Note
if you cannot `docker exec -it flex bash`, run following command to check logs:
```console
docker logs flex
```

## 3. Push blobfuse-flexvol-installer image
```console
docker login
docker tag $REPO_NAME/blobfuse-flexvol-installer:$VER $REPO_NAME/blobfuse-flexvol-installer:latest
docker push $REPO_NAME/blobfuse-flexvol-installer:latest
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
| 1.0.7 | N/A | fix: mountoptions don't allow blank space issue#4 |
| 1.0.8 | N/A | fix: invalid character 's' after object key:value pair#9 |
| 1.0.9 | N/A | add `driverpath`, `accountsastoken` parameters |
| 1.0.10 | N/A | ignore `fsGroup` setting([PR#40](https://github.com/Azure/kubernetes-volume-drivers/pull/40)) |
| 1.0.11 | N/A | add endpoint support([PR#42](https://github.com/Azure/kubernetes-volume-drivers/pull/42)) |
| 1.0.12 | N/A | fix sovereign cloud issue |
| 1.0.13 | N/A | fix blobfuse mkdir issue([PR#60](https://github.com/Azure/kubernetes-volume-drivers/pull/60)) |
| 1.0.14 | N/A | <br> - default `tmp-path` to `/mnt`([PR#60](https://github.com/Azure/kubernetes-volume-drivers/pull/86)) <br> - use random folder(`/mnt/blobfuse$RANDOM`) for `tmp-path` by default |
| 1.0.15 | N/A | fix: pod stuck in terminating issue([PR#89](https://github.com/Azure/kubernetes-volume-drivers/pull/89)) |
| 1.0.16 | N/A | fix: remove sub dir issue in blobfuse unmount([PR#93](https://github.com/Azure/kubernetes-volume-drivers/pull/93)) |
| 1.0.17 | N/A | fix: use busybox:1.32.0 to prevent security vulnerability issue |
| 1.0.18 | N/A | [fix: blobfuse restart when kubelet is restarted](https://github.com/Azure/kubernetes-volume-drivers/pull/104) |
