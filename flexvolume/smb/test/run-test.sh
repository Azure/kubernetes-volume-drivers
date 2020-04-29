#!/bin/bash

set -euo pipefail

DRIVER="flexvolume/smb/deployment/smb-flexvol-installer/smb"
MNTPATH="/tmp/smb-mnt"

echo "begin to run smb test ..."
echo "$DRIVER init test..."
sudo $DRIVER init
retcode=$?
if [ $retcode -gt 0 ]; then
        exit $retcode
fi

# to-do: $DRIVER unmount $MNTPATH {JSON-PARAM}

mkdir -p $MNTPATH
echo "$DRIVER unmount test..."
sudo $DRIVER unmount $MNTPATH
if [ $retcode -gt 0 ]; then
        exit $retcode
fi

echo "smb test is completed."
