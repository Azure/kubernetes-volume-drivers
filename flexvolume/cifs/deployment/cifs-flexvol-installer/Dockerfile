FROM ubuntu:16.04

ADD ./download_cifs.sh /bin/download_cifs.sh
ADD ./install.sh /bin/install_cifs_flexvol.sh

RUN apt-get update && apt-get install wget -y
RUN /bin/download_cifs.sh

ENTRYPOINT ["/bin/install_cifs_flexvol.sh"]
