FROM busybox

ADD ./install.sh /bin/install_blobfuse_flexvol.sh
RUN mkdir /blobfuse/
ADD ./blobfuse /blobfuse/blobfuse

ENTRYPOINT ["/bin/install_blobfuse_flexvol.sh"]
