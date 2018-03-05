FROM ubuntu:16.04

apt-get update && apt-get install wget -y

ADD ./install.sh /bin/install_blobfuse_flexvol.sh

ENTRYPOINT ["/bin/install_blobfuse_flexvol.sh"]
