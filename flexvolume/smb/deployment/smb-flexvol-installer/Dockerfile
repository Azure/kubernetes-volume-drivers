FROM busybox

ADD ./smb /bin/smb
ADD ./install.sh /bin/install_smb_flexvol.sh

ENTRYPOINT ["/bin/install_smb_flexvol.sh"]
