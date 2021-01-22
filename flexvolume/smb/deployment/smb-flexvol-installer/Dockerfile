###################################################
FROM python:slim as statically-linked-deps
###################################################

ARG INSTALL_DEPS=true
ENV SOURCE_DIR="/install-bin"

RUN \
  mkdir -p ${SOURCE_DIR} && \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    binutils \
    cifs-utils \
    jq \
    patchelf \
    && \
  apt-get clean && \
  pip3 install --no-cache-dir staticx && \
  staticx `which mount.cifs` ${SOURCE_DIR}/mount.cifs && \
  chmod +s ${SOURCE_DIR}/mount.cifs && \
  staticx `which jq` ${SOURCE_DIR}/jq

###################################################
FROM busybox:1.32.0
###################################################

ARG INSTALL_DEPS=false
ENV INSTALL_DEPS="$INSTALL_DEPS"
ENV SOURCE_DIR="/install-bin"
COPY --from=statically-linked-deps ${SOURCE_DIR} ${SOURCE_DIR}

ADD ./smb /bin/smb
ADD ./install.sh /bin/install_smb_flexvol.sh

ENTRYPOINT ["/bin/install_smb_flexvol.sh"]
