# use sh attach_detach_test_portworx.sh 500 default file.txt to test 500 pods with default sc and write results in file.txt.
# attach_detach_test_portworx.sh use pod in running state for attach test and pv deletion for detach test.
kubectl create ns test
predate=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag=0
pvcflag2=0
pvcflag3=0
p50=$(($1/2))
p90=$(($1/10*9))
p99=$(($1/100*99))
p100=$1
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefulset-local
  namespace: test
  labels:
    app: nginx
spec:
  podManagementPolicy: Parallel  # default is OrderedReady
  serviceName: statefulset-local
  replicas: $1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      nodeSelector:
        "kubernetes.io/os": linux
      containers:
        - name: statefulset-local
          image: mcr.microsoft.com/oss/nginx/nginx:1.19.5
          command:
            - "/bin/bash"
            - "-c"
            - set -euo pipefail; while true; do echo $(date) >> /mnt/local/outfile; sleep 1; done
          volumeMounts:
            - name: persistent-storage
              mountPath: /mnt/local
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: nginx
  volumeClaimTemplates:
    - metadata:
        name: persistent-storage
        annotations:
          volume.beta.kubernetes.io/storage-class: $2
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
EOF
readynum=$(kubectl get pod -n test --field-selector=status.phase==Running | awk 'END{print NR}')
while [ $readynum -le $p50 ]
do
pvcnum=$(kubectl get pvc -n test | grep Bound | awk 'END{print NR}')
if [ $pvcnum -ge $p50 ] && [ $pvcflag -eq 0 ]; then
date2=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag=1
echo "pv creation p50: $(( $(date -d "$date2" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
fi
if [ $pvcnum -ge $p90 ] && [ $pvcflag2 -eq 0 ]; then
date2=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag2=1
echo "pv creation p90: $(( $(date -d "$date2" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
fi
if [ $pvcnum -ge $p99 ] && [ $pvcflag3 -eq 0 ]; then
date2=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag3=1
echo "pv creation p99: $(( $(date -d "$date2" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
fi
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
readynum=$(kubectl get pod -n test --field-selector=status.phase==Running | awk 'END{print NR}')
done
echo "attach p50: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
while [ $readynum -le $p90 ]
do
pvcnum=$(kubectl get pvc -n test | grep Bound | awk 'END{print NR}')
if [ $pvcnum -ge $p90 ] && [ $pvcflag2 -eq 0 ]; then
date2=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag2=1
echo "pv creation p90: $(( $(date -d "$date2" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
fi
if [ $pvcnum -ge $p99 ] && [ $pvcflag3 -eq 0 ]; then
date2=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag3=1
echo "pv creation p99: $(( $(date -d "$date2" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
fi
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
readynum=$(kubectl get pod -n test --field-selector=status.phase==Running | awk 'END{print NR}')
done
echo "attach p90: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
while [ $readynum -le $p99 ]
do
pvcnum=$(kubectl get pvc -n test | grep Bound | awk 'END{print NR}')
if [ $pvcnum -ge $p99 ] && [ $pvcflag3 -eq 0 ]; then
date2=$(date +"%Y-%m-%d %H:%M:%S")
pvcflag3=1
echo "pv creation p99: $(( $(date -d "$date2" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
fi
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
readynum=$(kubectl get pod -n test --field-selector=status.phase==Running | awk 'END{print NR}')
done
echo "attach p99: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
while [ $readynum -le $p100 ]
do
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
readynum=$(kubectl get pod -n test --field-selector=status.phase==Running | awk 'END{print NR}')
done
echo "attach p100: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3

echo "sleep 5 minutes between attach and detach test..." >> $3
sleep 5m

predate=$(date +"%Y-%m-%d %H:%M:%S")
cat <<EOF | kubectl delete -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: statefulset-local
  namespace: test
  labels:
    app: nginx
spec:
  podManagementPolicy: Parallel  # default is OrderedReady
  serviceName: statefulset-local
  replicas: $1
  template:
    metadata:
      labels:
        app: nginx
    spec:
      nodeSelector:
        "kubernetes.io/os": linux
      containers:
        - name: statefulset-local
          image: mcr.microsoft.com/oss/nginx/nginx:1.19.5
          command:
            - "/bin/bash"
            - "-c"
            - set -euo pipefail; while true; do echo $(date) >> /mnt/local/outfile; sleep 1; done
          volumeMounts:
            - name: persistent-storage
              mountPath: /mnt/local
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: nginx
  volumeClaimTemplates:
    - metadata:
        name: persistent-storage
        annotations:
          volume.beta.kubernetes.io/storage-class: $2
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
EOF
kubectl delete pvc -n test --all &
detachnum=$(kubectl get pv | grep pvc- | awk 'END{print NR}')
while [ $detachnum -gt $((p100-p50)) ]
do
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
detachnum=$(kubectl get pv | grep pvc- | awk 'END{print NR}')
done
echo "detach p50: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
while [ $detachnum -gt $((p100-p90)) ]
do
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
detachnum=$(kubectl get pv | grep pvc- | awk 'END{print NR}')
done
echo "detach p90: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
while [ $detachnum -gt $((p100-p99)) ]
do
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
detachnum=$(kubectl get pv | grep pvc- | awk 'END{print NR}')
done
echo "detach p99: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
while [ $detachnum -gt 0 ]
do
sleep 1
date1=$(date +"%Y-%m-%d %H:%M:%S")
detachnum=$(kubectl get pv | grep pvc- | awk 'END{print NR}')
done
echo "detach p100: $(( $(date -d "$date1" "+%s") - $(date -d "$predate" "+%s") ))" >> $3
kubectl delete ns test
