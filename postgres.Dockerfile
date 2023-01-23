FROM debian:bullseye-slim

RUN apt update && apt install -y --no-install-recommends libzstd-dev liblz4-dev xz-utils locales wget build-essential llvm-dev clang pkg-config libicu-dev bison flex gettext libreadline-dev zlib1g-dev libssl-dev libossp-uuid-dev libzstd-dev liblz4-dev \
  && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
  && cd /root \
  && wget --no-check-certificate https://ftp.postgresql.org/pub/source/v15.1/postgresql-15.1.tar.gz \
  && tar zxf postgresql-15.1.tar.gz && mkdir build && cd build \
  && ../postgresql-15.1/configure --prefix=/usr/local --with-zstd --with-lz4 --enable-nls --build=x86_64-debian-linux --with-llvm --with-icu --with-openssl --with-ossp-uuid build_alias=x86_64-debian-linux \
  && make world -j 2 && make install-world \
  && cd .. && rm -rf postgresql* && rm -rf build \
  && addgroup --gid 70 postgres && useradd -s /bin/bash  -c postgres -d /data -g 70 -G postgres -m -u 70 postgres \
  && apt purge -y wget build-essential clang && apt autoremove -y && rm -rf /var/lib/apt/lists/*

USER postgres
VOLUME /data
EXPOSE 5432
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8
