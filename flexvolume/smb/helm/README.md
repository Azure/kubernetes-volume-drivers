# Getting an SMB-backed PersistentVolume going using this Helm chart

You can use this chart to add an SMB Share as a Volume
to your Kubernetes cluster. It enables SMB-based PersistentVolumes
on your cluster in general, so after deploying you can create as
many SMB-backed volumes as you'd like.

By default the helm chart deploys a PersistentVolume, a PersistentVolumeClaim,
a "Test" Pod for debugging the setup, and most importantly, a DaemonSet
which can install the SMB drivers (and dependencies: jq and cifs-utils)
on each node in your K8S cluster.

## Configure the smbVolume for your SMB server/share and deploy:

1. Edit `values.yaml` and configure lines marked *MUST CONFIGURE*:
  - Set `smbVolume.server`, `smbVolume.share` to access //smbVolume.server/smbVolume.share
  - Create an `smbcreds` secret on your k8s cluster with your SMB login credentials:
   ```
   kubectl create secret generic smbcreds --from-literal username=USERNAME --from-literal password="PASSWORD" --type="microsoft.com/smb"
   ```
  - Set `smbFlexVolInstaller.flexVolumePluginPath` to the correct path
    for your kubernetes platform provider (Azure AKS, minikube, etc, 
    see https://rook.io/docs/rook/master/flexvolume.html or comments in values.yaml)

2. Deploy the chart to your k8s cluster: 
   ```
   helm install --wait ./helm/smb-flexvol
   ```

## Use the testpod to validate your setup:

We recommend experimenting with your smbVolume and smbVolumeClaim in the testPod
until everything is working how you want.

3. Check if your smbVolume mounted to testPod.mountPath (/data by default):
  ```
  kubectl exec $(kubectl get pod -l "role=testpod" -o name) -- ls /data
  ```

4. Debug interactively on the testPod if necessary:
  ```
  kubectl exec -it $(kubectl get pod -l "role=testpod" -o name) -- bash
  ```

That's it! Happy helming!