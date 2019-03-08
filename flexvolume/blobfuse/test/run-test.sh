#!/bin/bash

set -euo pipefail

DRIVER="flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/blobfuse"
MNTPATH="/tmp/blobfuse-mnt"

echo "begin to run blobfuse test ..."
echo "$DRIVER init test..."
$DRIVER init
retcode=$?
if [ $retcode -gt 0 ]; then
	exit $retcode
fi

# to-do: $DRIVER unmount $MNTPATH {JSON-PARAM}

mkdir -p $MNTPATH
echo "$DRIVER unmount test..."
$DRIVER unmount $MNTPATH
if [ $retcode -gt 0 ]; then
	exit $retcode
fi

echo "blobfuse test is completed."
