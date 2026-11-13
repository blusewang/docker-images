FROM debian:trixie-slim

LABEL maintainer="Jeff Wang <jeff@wangjunfeng.com.cn>" \
    description="PostgreSQL Custom Edition"
    
ENV VERSION=19rc2

RUN set -x && \
# 安装构建工具及依赖
    apt-get update && apt-get install -y --no-install-recommends locales wget build-essential clang cmake openssl sudo zstd vim nano adduser \
    pkg-config llvm-dev libicu-dev bison flex gettext libreadline-dev zlib1g-dev libssl-dev libossp-uuid-dev libzstd-dev \
    liblz4-dev libzstd-dev liblz4-dev libxml2-dev docbook-xml docbook-xsl xsltproc opensp libxml2-utils sgml-data docbook-dsssl git && \
# 适配中国区时间及编码
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
# 构建
    wget --no-check-certificate https://ftp.postgresql.org/pub/source/v${VERSION}/postgresql-${VERSION}.tar.gz -O /tmp/pg.tar.gz && \
    mkdir /tmp/build && tar --strip=1 -xf /tmp/pg.tar.gz -C /tmp/build && cd /tmp/build && \
    ./configure --prefix=/usr --with-zstd --with-lz4 --enable-nls --with-llvm --with-openssl --with-ossp-uuid --with-libxml '--with-extra-version= (Jeff)' && \
    make world -j "$(nproc)" && make install-world && \
# 暂不需要
#    git config --global http.sslverify false && \
#    cd /tmp && git clone https://github.com/timescale/timescaledb && cd timescaledb && git checkout 2.17.2 && \
#    ./bootstrap && cd build && make world && make install-world && \
# 配置运行时需要的用户及应用级时区
    addgroup --gid 70 postgres && useradd -s /bin/bash  -c postgres -d /data -g 70 -G postgres -m -u 70 -p $(echo 'postgres' | openssl passwd -1 -stdin) postgres && \
    echo 'postgres ALL=(ALL) ALL' >> /etc/sudoers && \
    cp /usr/share/postgresql/timezonesets/Asia.txt /usr/share/postgresql/timezonesets/Asia && \
    sed -i 's|KST     32400|#KST     32400|g' /usr/share/postgresql/timezonesets/Asia && \
    sed -i 's|IST      7200|#IST      7200|g' /usr/share/postgresql/timezonesets/Asia && \
# 清理
    rm -rf /tmp/* && \
    apt-get purge -y wget build-essential clang cmake git && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
# docker配置
USER postgres
VOLUME /data
EXPOSE 5432
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8
CMD ["postgres -D /data/main"]
