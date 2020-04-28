# This image builds statically linked versions of 'jq' and 'cifs-utils'

FROM debian:stable as build-static-link-deps

ENV BUILD_DIR="/build"

# Build statically linked debs
ENV DEB_CFLAGS_PREPEND="-static"
ENV DEB_LDFLAGS_PREPEND="-static"
ENV DEB_CPPFLAGS_PREPEND="-static"
ENV DEB_CXXFLAGS_PREPEND="-static"
ENV DEB_BUILD_OPTIONS="nocheck"
#ENV LIBTOOLFLAGS="-all-static"

# Setup debian for doing package builds
RUN \
  apt-get update && \
  apt-get install --no-install-recommends -y \
    build-essential \
    devscripts \
    dpatch \
    equivs \
    fakeroot \
    # TODO: delete
    less \
    lintian \
    # TODO: delete
    nano \
    quilt \
    && \
  apt-get clean

# Get debian package source for jq & cifs-utils
RUN \
  echo '\
    deb-src http://deb.debian.org/debian stable main\n \
    deb-src http://security.debian.org/debian-security stable/updates main\n \
    ' >> /etc/apt/sources.list \
    && \
  apt update && \
  mkdir -p $BUILD_DIR && \
  cd $BUILD_DIR && \
  apt source \
    jq \
    cifs-utils \
    && \
  yes | mk-build-deps -i -r \
    jq \
    cifs-utils \
    && \
  apt-get clean

# Build cifs-utils deb
RUN \
  cd $BUILD_DIR/cifs-utils-* && \
  fakeroot debian/rules binary && \
  cd .. && \
  dpkg -i cifs-utils_*deb

# Build jq deb
RUN \
  printf "override_dh_auto_configure:\n\tdh_auto_configure -- --enable-all-static" >> debian/rules && \
  cd $BUILD_DIR/jq-* && \
   DEB_CONFIGURE_EXTRA_FLAGS="--enable-all-static" \
  fakeroot debian/rules binary
 
 # TODO: now copy them onto the target?