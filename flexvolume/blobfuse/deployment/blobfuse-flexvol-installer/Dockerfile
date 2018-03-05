FROM ubuntu:16.04

ADD ./download_blobfuse.sh /bin/download_blobfuse.sh
ADD ./install.sh /bin/install_blobfuse_flexvol.sh

RUN apt-get update && apt-get install wget -y
RUN /bin/download_blobfuse.sh

ENTRYPOINT ["/bin/install_blobfuse_flexvol.sh"]
