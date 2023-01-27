FROM alpine:3.16

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="Mosquitto MQTT Custom Edition Broker"

ENV VERSION=2.0.15 \
    DOWNLOAD_SHA256=4735b1d32e3f91c7a8896741d88a3022e89730a1ee897946decfa0df27039ac6 \
    GPG_KEYS=A0D6EEA1DCAE49A635A3B2F0779B22DFB3E717B7 \
    LWS_VERSION=4.2.1 \
    LWS_SHA256=842da21f73ccba2be59e680de10a8cce7928313048750eb6ad73b6fa50763c51 \
    MDM_VERSION=1.1.2

RUN set -x && \
    apk --no-cache add --virtual build-deps \
        build-base \
        cmake \
        cjson-dev \
        gnupg \
        linux-headers \
        openssl-dev \
        util-linux-dev && \
    wget https://github.com/warmcat/libwebsockets/archive/v${LWS_VERSION}.tar.gz -O /tmp/lws.tar.gz && \
    echo "$LWS_SHA256  /tmp/lws.tar.gz" | sha256sum -c - && \
    mkdir -p /build/lws && \
    tar --strip=1 -xf /tmp/lws.tar.gz -C /build/lws && \
    rm /tmp/lws.tar.gz && \
    cd /build/lws && \
    cmake . \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DDISABLE_WERROR=ON \
        -DLWS_IPV6=ON \
        -DLWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
        -DLWS_WITHOUT_CLIENT=ON \
        -DLWS_WITHOUT_EXTENSIONS=ON \
        -DLWS_WITHOUT_TESTAPPS=ON \
        -DLWS_WITH_EXTERNAL_POLL=ON \
        -DLWS_WITH_HTTP2=OFF \
        -DLWS_WITH_SHARED=OFF \
        -DLWS_WITH_ZIP_FOPS=OFF \
        -DLWS_WITH_ZLIB=OFF && \
    make -j "$(nproc)" && make install && \
    rm -rf /root/.cmake && \
    
    wget https://mosquitto.org/files/source/mosquitto-${VERSION}.tar.gz -O /tmp/mosq.tar.gz && \
    echo "$DOWNLOAD_SHA256  /tmp/mosq.tar.gz" | sha256sum -c - && \
    wget https://mosquitto.org/files/source/mosquitto-${VERSION}.tar.gz.asc -O /tmp/mosq.tar.gz.asc && \
    export GNUPGHOME="$(mktemp -d)" && \
    found=''; \
    for server in \
        hkps://keys.openpgp.org \
        hkp://keyserver.ubuntu.com:80 \
        pgp.mit.edu \
    ; do \
        echo "Fetching GPG key $GPG_KEYS from $server"; \
        gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEYS" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEYS" && exit 1; \
    gpg --batch --verify /tmp/mosq.tar.gz.asc /tmp/mosq.tar.gz && \
    gpgconf --kill all && \
    rm -rf "$GNUPGHOME" /tmp/mosq.tar.gz.asc && \
    mkdir -p /build/mosq && \
    tar --strip=1 -xf /tmp/mosq.tar.gz -C /build/mosq && \
    rm /tmp/mosq.tar.gz && \
    cd /build/mosq && \
    sed -i 's|prefix?=/usr/local|prefix?=/usr|g' config.mk && \
    sed -i 's|WITH_DOCS:=yes|WITH_DOCS:=no|g' config.mk && \
    sed -i 's|WITH_WEBSOCKETS:=no|WITH_WEBSOCKETS:=yes|g' config.mk && \
    make -j "$(nproc)" && make install && \
    addgroup -S -g 1883 mosquitto 2>/dev/null && \
    adduser -S -u 1883 -D -H -h /var/empty -s /sbin/nologin -G mosquitto -g mosquitto mosquitto 2>/dev/null && \
    mkdir -p /data && chown mosquitto:mosquitto /data && \
    
    wget https://github.com/blusewang/mosquitto-delay-message/archive/refs/tags/${MDM_VERSION}.tar.gz -O /tmp/mdm.tar.gz && \
    mkdir -p /build/mdm && \
    tar --strip=1 -xf /tmp/mdm.tar.gz -C /build/mdm && \
    rm /tmp/mdm.tar.gz && \
    sed -i 's|set(CMAKE_INSTALL_LIBDIR /usr/local/lib)|set(CMAKE_INSTALL_LIBDIR /usr/lib)|g' /build/mdm/CMakeLists.txt && \
    cd /build/mdm && \
    cmake . && \
    make -j "$(nproc)" && make install && \
    rm -rf /root/.cmake && \
    chown -R mosquitto:mosquitto /data && \
    apk --no-cache add \
        ca-certificates \
        cjson && \
    apk del build-deps && \
    mkdir /data && \
    rm -rf /build && rm -rf /tmp/* \

VOLUME /data
USER mosquitto
EXPOSE 1883 1884 1885 1886
CMD ["/usr/local/sbin/mosquitto", "-c", "/data/mosquitto.conf"]
