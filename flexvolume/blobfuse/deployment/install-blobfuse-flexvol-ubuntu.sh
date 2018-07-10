#!/bin/sh
VER="1.0.0"

echo "install blobfuse, jq packages ..."
PKG_TARGET=/tmp/packages-microsoft-prod.deb
wget -O $PKG_TARGET https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb > 
dpkg -i $PKG_TARGET
apt update
apt-get install blobfuse fuse jq -y

echo "install blobfuse flexvolume driver ..."
PLUGIN_DIR=/etc/kubernetes/volumeplugins/azure~blobfuse
mkdir -p $PLUGIN_DIR
wget -O $PLUGIN_DIR/blobfuse https://raw.githubusercontent.com/Azure/kubernetes-volume-drivers/master/flexvolume/blobfuse/deployment/blobfuse-flexvol-installer/blobfuse
chmod a+x $PLUGIN_DIR/blobfuse

echo "install complete."
