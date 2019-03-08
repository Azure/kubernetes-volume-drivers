#!/bin/sh

LOG="/var/log/blobfuse-flexvol-installer.log"
VER="1.0.9"
target_dir="${TARGET_DIR}"

if [[ -z "${target_dir}" ]]; then
  target_dir="/etc/kubernetes/volumeplugins"
fi

echo "begin to install blobfuse FlexVolume driver ${VER}, target dir:${target_dir} ..." >> $LOG

blobfuse_vol_dir="${target_dir}/azure~blobfuse"
mkdir -p ${blobfuse_vol_dir} >>$LOG 2>&1

#copy blobfuse script
cp /blobfuse/blobfuse ${blobfuse_vol_dir}/blobfuse >>$LOG 2>&1
chmod a+x ${blobfuse_vol_dir}/blobfuse >>$LOG 2>&1

echo "install blobfuse FlexVolume driver completed." >> $LOG

#https://github.com/kubernetes/kubernetes/issues/17182
# if we are running on kubernetes cluster as a daemon set we should
# not exit otherwise, container will restart and goes into crashloop (even if exit code is 0)
while true; do echo "install done, daemonset sleeping" && sleep 3600; done
