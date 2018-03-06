#!/bin/sh

LOG="/var/log/cifs-flexvol-installer.log"
VER="1.0.0"
target_dir="${TARGET_DIR}"
echo "cifs-flexvol-installer ${VER}" >> $LOG
echo "being to install cifs flex volume driver..." >> $LOG

if [[ -z "${target_dir}" ]]; then
  target_dir="/etc/kubernetes/volumeplugins"
fi

cifs_vol_dir="${target_dir}/azure~cifs"
mkdir -p ${cifs_vol_dir} >> $LOG 2>&1

#copy cifs script
cp /bin/cifs ${cifs_vol_dir}/cifs >> $LOG 2>&1
chmod a+x ${cifs_vol_dir}/cifs >> $LOG 2>&1

echo "install cifs flex volume driver completed." >> $LOG

#https://github.com/kubernetes/kubernetes/issues/17182
# if we are running on kubernetes cluster as a daemon set we should
# not exit otherwise, container will restart and goes into crashloop (even if exit code is 0)
while true; do echo "install done, daemonset sleeping" && sleep 30; done
