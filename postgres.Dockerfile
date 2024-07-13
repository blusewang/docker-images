FROM debian:bullseye-slim

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="PostgreSQL Custom Edition"
    
ENV VERSION=16.3

RUN apt update && apt install -y --no-install-recommends locales wget build-essential clang cmake openssl sudo \
    pkg-config llvm-dev libicu-dev bison flex gettext libreadline-dev zlib1g-dev libssl-dev libossp-uuid-dev libzstd-dev \
    liblz4-dev libzstd-dev liblz4-dev libxml2-dev git && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \

    wget --no-check-certificate https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz -O /tmp/pg.tar.gz && \
    mkdir /tmp/build && tar --strip=1 -xf /tmp/pg.tar.gz -C /tmp/build && cd /tmp/build && \
    ./configure --prefix=/usr --with-zstd --with-lz4 --enable-nls --build=x86_64-debian-linux --with-llvm --with-openssl --with-ossp-uuid --with-libxml build_alias=x86_64-debian-linux && \
    make world -j "$(nproc)" && make install-world && \

    git config --global http.sslverify false && \
    cd /tmp && git clone https://github.com/jaiminpan/pg_jieba && cd pg_jieba && git submodule update --init --recursive && \
    mkdir build && cd build && cmake .. && make && make install && \

    wget --no-check-certificate https://github.com/apache/age/releases/download/PG16%2Fv1.5.0-rc0/apache-age-1.5.0-src.tar.gz -O /tmp/age.tar.gz && \
    mkdir /tmp/age && tar --strip=1 -xf /tmp/age.tar.gz -C /tmp/age && cd /tmp/age && make && make install && \

    wget --no-check-certificate https://github.com/paradedb/paradedb/releases/download/v0.8.3/pg_lakehouse-v0.8.3-debian-12-arm64-pg16.deb -O /tmp/pg_lakehouse-v0.8.3-debian-12-arm64-pg16.deb && \
    apt-get install -y /tmp/pg_lakehouse-v0.8.3-debian-12-arm64-pg16.deb && \


    addgroup --gid 70 postgres && useradd -s /bin/bash  -c postgres -d /data -g 70 -G postgres -m -u 70 -p $(echo 'postgres' | openssl passwd -1 -stdin) postgres && \
    echo 'postgres ALL=(ALL) ALL' >> /etc/sudoers && \
    cp /usr/share/postgresql/timezonesets/Asia.txt /usr/share/postgresql/timezonesets/Asia && \
    sed -i 's|KST     32400|#KST     32400|g' /usr/share/postgresql/timezonesets/Asia && \
    sed -i 's|IST      7200|#IST      7200|g' /usr/share/postgresql/timezonesets/Asia && \

    rm -rf /tmp/* && \
    apt purge -y wget build-essential clang cmake git && apt autoremove -y && rm -rf /var/lib/apt/lists/*

USER postgres
VOLUME /data
EXPOSE 5432
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8
CMD ["postgres -D /data/main"]
