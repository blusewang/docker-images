FROM debian:bullseye-slim

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="PostgreSQL Custom Edition"
    
ENV VERSION=15.4

RUN apt update && apt install -y --no-install-recommends locales wget build-essential clang cmake openssl sudo \
    pkg-config llvm-dev libicu-dev bison flex gettext libreadline-dev zlib1g-dev libssl-dev libossp-uuid-dev libzstd-dev \
    liblz4-dev libzstd-dev liblz4-dev libxml2-dev && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \

    wget --no-check-certificate https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz -O /tmp/pg.tar.gz && \
    mkdir /tmp/build && tar --strip=1 -xf /tmp/pg.tar.gz -C /tmp/build && cd /tmp/build && \
    ./configure --prefix=/usr --with-zstd --with-lz4 --enable-nls --build=x86_64-debian-linux --with-llvm --with-icu --with-openssl --with-ossp-uuid --with-libxml build_alias=x86_64-debian-linux && \
    make world -j "$(nproc)" && make install-world && \

    wget --no-check-certificate https://github.com/timescale/timescaledb/archive/refs/tags/2.11.2.tar.gz -O /tmp/ts.tar.gz && \
    mkdir /tmp/mkts && tar --strip=1 -xf /tmp/ts.tar.gz -C /tmp/mkts && cd /tmp/mkts && \
    ./bootstrap && cd build && make && make install && \

    addgroup --gid 70 postgres && useradd -s /bin/bash  -c postgres -d /data -g 70 -G postgres -m -u 70 -p $(echo 'postgres' | openssl passwd -1 -stdin) postgres && \
    echo 'postgres ALL=(ALL) ALL' >> /etc/sudoers && \
    cp /usr/share/postgresql/timezonesets/Asia.txt /usr/share/postgresql/timezonesets/Asia && \
    sed -i 's|KST     32400|#KST     32400|g' /usr/share/postgresql/timezonesets/Asia && \
    sed -i 's|IST      7200|#IST      7200|g' /usr/share/postgresql/timezonesets/Asia && \

    rm -rf /tmp/* && \
    apt purge -y wget build-essential clang cmake && apt autoremove -y && rm -rf /var/lib/apt/lists/*

USER postgres
VOLUME /data
EXPOSE 5432
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8
CMD ["postgres -D /data/main"]
