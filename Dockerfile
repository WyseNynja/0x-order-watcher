FROM gitlab-registry.stytt.com/docker/linux-s6-consul/debian

ENV PYTHON python2.7
RUN docker-install \
    build-essential \
    dirmngr \
    git \
    python2.7 \
    xz-utils \
;

# based on https://github.com/nodejs/docker-node/blob/120b465c249cf08d7939a3a0c07fec897cfcf91d/10/stretch/Dockerfile
# v10 is a LTS release
ENV NODE_VERSION 10.13.0
RUN set -ex \
  && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && export GNUPGHOME="$(mktemp -d -p /tmp)" \
  # gpg keys listed at https://github.com/nodejs/node#release-team
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  ; do \
    gpg --no-tty --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --no-tty --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --no-tty --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --no-tty --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  && rm -rf /tmp/*
ENV YARN_VERSION 1.10.1
RUN set -ex \
  && export GNUPGHOME="$(mktemp -d -p /tmp)" \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && cd /tmp \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --no-tty --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm -rf /tmp/*
# END https://github.com/nodejs/docker-node/blob/120b465c249cf08d7939a3a0c07fec897cfcf91d/10/stretch/Dockerfile

RUN mkdir -p /usr/src/myapp
WORKDIR /usr/src/myapp

# install dependencies
COPY ./src/package.json .
COPY ./src/yarn.lock .
RUN yarn install

# install the app
COPY ./src/ .
RUN yarn install

COPY ./rootfs/ /

# thanks to consul connect, we can use localhost for TLS connections to remote services
#    ETHEREUM_WS_PROVIDER=ws://localhost:8546 \
ENV RELAYER_HTTP=http://localhost:3000/api/0x/v2/order/ \
    ETHEREUM_HTTP_PROVIDER=http://localhost:8545 \
    ETHEREUM_WS_PROVIDER=http://localhost:8546 \
    ETHEREUM_NETWORK_ID=1 \
    WATCHER_PORT=3001

# ENV RELAYER_HTTP=http://localhost:3000/api/0x/v2/order/ \
#     ETHEREUM_HTTP_PROVIDER=http://localhost:8645 \
#     ETHEREUM_NETWORK_ID=42 \
#     WATCHER_PORT=3001
