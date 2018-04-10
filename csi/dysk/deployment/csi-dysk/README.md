## 1. Build csi-dysk image

```
cd ~/go/src/github.com/kubernetes-csi/drivers
make dysk
docker build --no-cache -t andyzhangx/csi-dysk:1.0.0 -f ./app/dyskplugin/Dockerfile .
#docker login
docker push andyzhangx/csi-dysk:1.0.0
```

## 2. Test csi-dysk image
```
docker run -it --name csi-dysk andyzhangx/csi-dysk:1.0.0 --nodeid=abc bash
docker stop csi-dysk && docker rm csi-dysk
```

### Links
 - [csi-dysk code](https://github.com/andyzhangx/drivers/tree/dysk-init)
