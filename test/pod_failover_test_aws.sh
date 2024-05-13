# use sh pod_failover_test_aws.sh 100 file.txt to test 1 pod 3 pvc pod failover test on aws for 100 times and write results in file.txt.
kubectl create ns ebs-pod-failover-1pod3pvc
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-pod-failover-1pod3pvc-sc
parameters:
  csi.storage.k8s.io/fstype: xfs
  type: gp2
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
allowVolumeExpansion: true
EOF

cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  annotations:
    meta.helm.sh/release-name: pod-failover-workload
    meta.helm.sh/release-namespace: default
  generation: 1
  labels:
    app: pod-failover
    app.kubernetes.io/managed-by: Helm
  name: pod-failover-statefulset
  namespace: ebs-pod-failover-1pod3pvc
spec:
  podManagementPolicy: Parallel
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: pod-failover
  serviceName: ebs-pod-failover-1pod3pvc-service
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: pod-failover
        failureType: delete-pod
    spec:
      containers:
      - args:
        - --mount-path=/mnt/ebs-pod-failover-1pod3pvc-0
        - --run-id=33159
        - --workload-type=1pod3pvc
        - --storage-provisioner=ebs.csi.aws.com
        - --namespace=ebs-pod-failover-1pod3pvc
        env:
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        image: umagnus/workloadpod
        imagePullPolicy: Always
        lifecycle:
          preStop:
            httpGet:
              path: /cleanup
              port: 9091
              scheme: HTTP
        name: pod-failover-workload
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /mnt/ebs-pod-failover-1pod3pvc-0
          name: volume-0
        - mountPath: /mnt/ebs-pod-failover-1pod3pvc-1
          name: volume-1
        - mountPath: /mnt/ebs-pod-failover-1pod3pvc-2
          name: volume-2
      dnsPolicy: ClusterFirst
      nodeSelector:
        kubernetes.io/os: linux
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      terminationGracePeriodSeconds: 30
  updateStrategy:
    rollingUpdate:
      partition: 0
    type: RollingUpdate
  volumeClaimTemplates:
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      creationTimestamp: null
      name: volume-0
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: ebs-pod-failover-1pod3pvc-sc
      volumeMode: Filesystem
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      creationTimestamp: null
      name: volume-1
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: ebs-pod-failover-1pod3pvc-sc
      volumeMode: Filesystem
  - apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      creationTimestamp: null
      name: volume-2
    spec:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 1Gi
      storageClassName: ebs-pod-failover-1pod3pvc-sc
      volumeMode: Filesystem
status:
  availableReplicas: 0
  collisionCount: 0
  currentReplicas: 1
  currentRevision: pod-failover-statefulset-8565df4b89
  observedGeneration: 1
  replicas: 1
  updateRevision: pod-failover-statefulset-8565df4b89
  updatedReplicas: 1
EOF
readynum=$(kubectl get pod -n ebs-pod-failover-1pod3pvc --field-selector=status.phase==Running | awk 'END{print NR}')
while [ $readynum -le 1 ]
do
sleep 1
readynum=$(kubectl get pod -n ebs-pod-failover-1pod3pvc --field-selector=status.phase==Running | awk 'END{print NR}')
done
for i in $(seq $1)
do
nodename=$(kubectl get po pod-failover-statefulset-0 -n ebs-pod-failover-1pod3pvc -o custom-columns=NODE:.spec.nodeName --no-headers)
kubectl cordon $nodename
kubectl delete pod pod-failover-statefulset-0 -n ebs-pod-failover-1pod3pvc
predate=$(date +"%Y-%m-%d %H:%M:%S")
readynum=$(kubectl get pod -n ebs-pod-failover-1pod3pvc --field-selector=status.phase==Running | awk 'END{print NR}')
while [ $readynum -le 1 ]
do
sleep 1
date=$(date +"%Y-%m-%d %H:%M:%S")
readynum=$(kubectl get pod -n ebs-pod-failover-1pod3pvc --field-selector=status.phase==Running | awk 'END{print NR}')
done
echo "`date` test $i: $(( $(date -d "$date" "+%s") - $(date -d "$predate" "+%s") ))" >> $2
kubectl uncordon $nodename
done
kubectl delete ns ebs-pod-failover-1pod3pvc
kubectl delete storageclass ebs-pod-failover-1pod3pvc-sc
