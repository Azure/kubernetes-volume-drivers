FROM busybox

ADD ./cifs /bin/cifs
ADD ./install.sh /bin/install_cifs_flexvol.sh

ENTRYPOINT ["/bin/install_cifs_flexvol.sh"]
