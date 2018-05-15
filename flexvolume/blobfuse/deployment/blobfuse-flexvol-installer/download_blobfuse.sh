#!/bin/sh

BLOBFUSE_VERSION="v1.0.0-RC"
for version in "v1.7" "v1.8" "v1.9"
do
	blobfuse_bin_dir=./blobfuse/hyperkube-$version/$BLOBFUSE_VERSION/
	mkdir -p ${blobfuse_bin_dir}
	wget -O ${blobfuse_bin_dir}/blobfuse https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/binary/hyperkube-$version/$BLOBFUSE_VERSION/blobfuse
	chmod a+x ${blobfuse_bin_dir}/blobfuse
done

wget -O ./blobfuse/blobfuse https://raw.githubusercontent.com/andyzhangx/kubernetes-drivers/master/flexvolume/blobfuse/blobfuse
