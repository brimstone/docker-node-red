FROM node:alpine

# Build Open-Zwave

COPY open-zwave /opt/open-zwave/

RUN apk --update add build-base python libcap eudev shadow \
 && apk --update add --virtual build-dependencies build-base linux-headers eudev-dev coreutils \
 && cd /opt/open-zwave \
 && make -j4 \
 && make install \
 && apk del build-dependencies

# Allow node to bind to port 80 as a regular user
RUN setcap cap_net_bind_service=+ep /usr/local/bin/node

# Home directory for Node-RED application source code.
RUN mkdir -p /usr/src/node-red /data

# User data directory, contains flows, config and nodes.
WORKDIR /usr/src/node-red
COPY settings.js /data.orig/

# Entrypoint
ENTRYPOINT ["/loader"]

# Add node-red user so we aren't running as root.
RUN adduser -h /usr/src/node-red -D -H node-red \
 && chown -R node-red:node-red /data \
 && chown -R node-red:node-red /usr/src/node-red
USER node-red

# package.json contains Node-RED NPM module and node dependencies
COPY package.json /usr/src/node-red/
RUN npm install

# User configuration directory volume
VOLUME ["/data"]
EXPOSE 80

# Environment variable holding file path for flows configuration
ENV FLOWS=flows.json \
    SECURITY_KEY=""

USER root
COPY loader /
