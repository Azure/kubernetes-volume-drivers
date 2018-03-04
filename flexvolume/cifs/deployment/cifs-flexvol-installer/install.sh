#!/bin/bash

LOG="/var/log/cifs-flexvol-installer.log"
VER="1.0.0"
target_dir="${TARGET_DIR}"
echo "cifs-flexvol-installer ${VER}" >> $LOG

if [[ -z "${target_dir}" ]]; then
  target_dir="/etc/kubernetes/volumeplugins"
fi

apt-get update && apt-get install wget -y >>$LOG 2>&1

cifs_vol_dir="${target_dir}/azure~cifs"
mkdir -p ${cifs_vol_dir}

#download cifs script
wget -O ${cifs_vol_dir}/cifs https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/cifs/cifs >>$LOG 2>&1
chmod a+x ${cifs_vol_dir}/cifs

#https://github.com/kubernetes/kubernetes/issues/17182
# if we are running on kubernetes cluster as a daemon set we should
# not exit otherwise, container will restart and goes into crashloop (even if exit code is 0)
while true; do echo "install done, daemonset sleeping" && sleep 30; done
