## 1. Build csi-hostpath image

```
cd ~/go/src/github.com/kubernetes-csi/drivers
dep ensure -vendor-only
make hostpath
#_output/hostpathplugin
docker build --no-cache -t andyzhangx/csi-hostpath:0.5.0 -f ./app/hostpathplugin/Dockerfile .
#docker login
docker push andyzhangx/csi-hostpath:0.5.0
```

## 2. Test csi-hostpath image
```
docker run -it --name csi-hostpath andyzhangx/csi-hostpath:0.5.0 --nodeid=abc bash
docker stop csi-hostpath && docker rm csi-hostpath
```
