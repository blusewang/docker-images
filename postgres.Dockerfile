FROM debian:bullseye-slim

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="PostgreSQL Custom Edition"
    
ENV VERSION=15.1

RUN apt update && apt install -y --no-install-recommends locales wget build-essential clang \
    pkg-config llvm-dev libicu-dev bison flex gettext libreadline-dev zlib1g-dev libssl-dev libossp-uuid-dev libzstd-dev liblz4-dev libzstd-dev liblz4-dev && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \

    wget --no-check-certificate https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz -O /tmp/pg.tar.gz && \
    mkdir /tmp/build && tar --strip=1 -xf /tmp/pg.tar.gz -C /tmp/build && cd /tmp/build && \
    ./configure --prefix=/usr --with-zstd --with-lz4 --enable-nls --build=x86_64-debian-linux --with-llvm --with-icu --with-openssl --with-ossp-uuid build_alias=x86_64-debian-linux && \
    make world -j "$(nproc)" && make install-world && \

    addgroup --gid 70 postgres && useradd -s /bin/bash  -c postgres -d /data -g 70 -G postgres -m -u 70 postgres && \
    mkdir /data && chown postgres:postgres /data && \

    rm -rf /tmp/* && \
    apt purge -y wget build-essential clang && apt autoremove -y && rm -rf /var/lib/apt/lists/*

USER postgres
VOLUME /data
EXPOSE 5432
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8
CMD ["postgres -D /data/main"]
