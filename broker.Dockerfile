FROM debian:trixie-slim

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="Mosquitto MQTT Custom Edition Broker"

ENV VERSION=2.1.4 \
    MDM_VERSION=1.1.2

RUN set -ex && \
    apt-get update && apt-get install -y --no-install-recommends \
        locales wget ca-certificates build-essential cmake sudo openssl \
        libcjson1 libssl3t64 libedit2 libmicrohttpd12t64 libsqlite3-0 \
        libcjson-dev libssl-dev libedit-dev libmicrohttpd-dev libsqlite3-dev && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && \
    /usr/sbin/locale-gen && \
    \
    wget --no-check-certificate https://mosquitto.org/files/source/mosquitto-${VERSION}.tar.gz -O /tmp/mosq.tar.gz && \
    mkdir -p /build/mosq && \
    tar --strip=1 -xf /tmp/mosq.tar.gz -C /build/mosq && \
    cd /build/mosq && \
    cmake -B build \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib \
        -DWITH_DOCS=OFF \
        -DWITH_TESTS=OFF \
        -DWITH_WEBSOCKETS=ON \
        -DWITH_WEBSOCKETS_BUILTIN=ON && \
    cmake --build build -j "$(nproc)" && \
    cmake --install build && \
    ldconfig && \
    \
    wget --no-check-certificate https://github.com/blusewang/mosquitto-delay-message/archive/refs/tags/${MDM_VERSION}.tar.gz -O /tmp/mdm.tar.gz && \
    mkdir -p /build/mdm && \
    tar --strip=1 -xf /tmp/mdm.tar.gz -C /build/mdm && \
    sed -i 's|set(CMAKE_INSTALL_LIBDIR /usr/local/lib)|set(CMAKE_INSTALL_LIBDIR /usr/lib)|g' /build/mdm/CMakeLists.txt && \
    cd /build/mdm && \
    cmake . && \
    make -j "$(nproc)" && make install && \
    \
    mkdir -p /data && \
    groupadd --gid 1883 mosquitto && \
    useradd -s /bin/bash -c mosquitto -d /data -g 1883 -G mosquitto -m -u 1883 -p "$(echo 'mosquitto' | openssl passwd -1 -stdin)" mosquitto && \
    echo 'mosquitto ALL=(ALL) ALL' >> /etc/sudoers && \
    chown mosquitto:mosquitto /data && \
    \
    rm -rf /tmp/* /build && \
    apt-get purge -y wget build-essential cmake \
        libcjson-dev libssl-dev libedit-dev libmicrohttpd-dev libsqlite3-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# mosquitto-gdb 扩展：源码私有，仓库只提交预编译产物（用 build-gdb.sh 重新生成）
ARG TARGETARCH
COPY prebuilt/ /opt/mosquitto-gdb/
RUN set -eux; \
    arch="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    if [ -f "/opt/mosquitto-gdb/libgdb-${arch}.so" ]; then \
        install -m 0644 "/opt/mosquitto-gdb/libgdb-${arch}.so" /usr/lib/libgdb.so; \
    else \
        echo "WARNING: prebuilt/libgdb-${arch}.so 不存在，该架构不安装 mosquitto-gdb 扩展"; \
    fi; \
    rm -rf /opt/mosquitto-gdb

VOLUME /data
USER mosquitto
EXPOSE 1883 1884 1885 1886
CMD ["/usr/sbin/mosquitto", "-c", "/data/mosquitto.conf"]
