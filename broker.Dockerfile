FROM debian:bullseye-slim

RUN set -eux; \
  apt update && apt install -y --no-install-recommends locales wget build-essential cmake libssl-dev libcjson-dev \
  && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'zh_CN.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
  && cd /root \
  && wget --no-check-certificate https://github.com/warmcat/libwebsockets/archive/refs/tags/v4.3.1.tar.gz \
  && tar zxf v4.3.1.tar.gz && mkdir libws && cd libws \
  && cmake -DLWS_WITH_EXTERNAL_POLL=ON -DLWS_WITH_HTTP2=ON -DLWS_WITHOUT_TESTAPPS=ON -DLWS_UNIX_SOCK=ON ../libwebsockets-4.3.1 \
  && make -j 3 && make install && cd .. \
  && wget --no-check-certificate https://mosquitto.org/files/source/mosquitto-2.0.15.tar.gz && tar zxf mosquitto-2.0.15.tar.gz && cd mosquitto-2.0.15 \
  && sed -i 's/WITH_WEBSOCKETS:=no/WITH_WEBSOCKETS:=yes/g' config.mk \
  && sed -i 's/WITH_DOCS:=yes/WITH_DOCS:=no/g' config.mk \
  && make -j 3 && make install && cd .. \
  && wget --no-check-certificate https://github.com/blusewang/mosquitto-delay-message/archive/refs/tags/1.1.1.tar.gz -O 1.1.1.tar.gz \
  && tar zxf 1.1.1.tar.gz && cd mosquitto-delay-message-1.1.1 && cmake . && make && make install \
  && cd /root && rm -rf /root/* \
  && apt purge -y wget build-essential cmake && apt autoremove -y && rm -rf /var/lib/apt/lists/*

VOLUME /data
EXPOSE 1883 1884 1885 1886
ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN.UTF-8
