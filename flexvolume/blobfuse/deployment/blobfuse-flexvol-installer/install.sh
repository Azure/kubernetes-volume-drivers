#!/bin/bash

LOG="/var/log/blobfuse-flexvol-installer.log"
VER="1.0.0"
BLOBFUSE_VERSION="v0.2.4"
target_dir="${TARGET_DIR}"
echo "blobfuse-flexvol-installer ${VER}" >> $LOG

if [[ -z "${target_dir}" ]]; then
  target_dir="/etc/kubernetes/volumeplugins"
fi

blobfuse_vol_dir="${target_dir}/azure~blobfuse"
blobfuse_bin_dir="${blobfuse_vol_dir}/bin"
mkdir -p ${blobfuse_bin_dir}

#download blobfuse binary
version="v1.9"
if [[ -z "${KUBELET_VERSION}" ]]; then
	echo "ERR: could not get env var: KUBELET_VERSION, use default kubelet version ${version}" >>$LOG 2>&1
else
	version=`echo ${KUBELET_VERSION} | awk -F '.' '{print $1"."$2}'`
fi

#copy blobfuse binary
cp /blobfuse/hyperkube-$version/$BLOBFUSE_VERSION/blobfuse ${blobfuse_bin_dir}/blobfuse
chmod a+x ${blobfuse_bin_dir}/blobfuse

#copy blobfuse script
cp /blobfuse/blobfuse ${blobfuse_vol_dir}/blobfuse
chmod a+x ${blobfuse_vol_dir}/blobfuse

#https://github.com/kubernetes/kubernetes/issues/17182
# if we are running on kubernetes cluster as a daemon set we should
# not exit otherwise, container will restart and goes into crashloop (even if exit code is 0)
while true; do echo "install done, daemonset sleeping" && sleep 30; done
