FROM debian:bullseye-slim

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="Mosquitto MQTT Custom Edition Broker"

ENV VERSION=2.0.15 \
    LWS_VERSION=4.2.1 \
    MDM_VERSION=1.1.2

RUN set -x && \
    apt update && apt install -y --no-install-recommends locales wget build-essential cmake  \
    libcjson-dev libssl-dev && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
    
    wget --no-check-certificate https://github.com/warmcat/libwebsockets/archive/v${LWS_VERSION}.tar.gz -O /tmp/lws.tar.gz && \
    mkdir -p /build/lws && \
    tar --strip=1 -xf /tmp/lws.tar.gz -C /build/lws && \
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
        
    wget --no-check-certificate https://mosquitto.org/files/source/mosquitto-${VERSION}.tar.gz -O /tmp/mosq.tar.gz && \
    mkdir -p /build/mosq && \
    tar --strip=1 -xf /tmp/mosq.tar.gz -C /build/mosq && \
    cd /build/mosq && \
    sed -i 's|prefix?=/usr/local|prefix?=/usr|g' config.mk && \
    sed -i 's|WITH_DOCS:=yes|WITH_DOCS:=no|g' config.mk && \
    sed -i 's|WITH_WEBSOCKETS:=no|WITH_WEBSOCKETS:=yes|g' config.mk && \
    make -j "$(nproc)" && make install && \

    wget --no-check-certificate https://github.com/blusewang/mosquitto-delay-message/archive/refs/tags/${MDM_VERSION}.tar.gz -O /tmp/mdm.tar.gz && \
    mkdir -p /build/mdm && \
    tar --strip=1 -xf /tmp/mdm.tar.gz -C /build/mdm && \
    sed -i 's|set(CMAKE_INSTALL_LIBDIR /usr/local/lib)|set(CMAKE_INSTALL_LIBDIR /usr/lib)|g' /build/mdm/CMakeLists.txt && \
    cd /build/mdm && \
    cmake . && \
    make -j "$(nproc)" && make install && \

    mkdir /data && \
    addgroup --gid 1883 mosquitto && useradd -s /bin/bash  -c mosquitto -d /data -g 1883 -G mosquitto -m -u 1883 mosquitto && \
    chown mosquitto:mosquitto /data && \
    
    rm -rf /tmp/* && rm -rf /build && \
    apt purge -y wget build-essential cmake wget && apt autoremove -y && rm -rf /var/lib/apt/lists/*
    

VOLUME /data
USER mosquitto
EXPOSE 1883 1884 1885 1886
CMD ["/usr/sbin/mosquitto", "-c", "/data/mosquitto.conf"]
