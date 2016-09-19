# elabftw in docker, without sql
FROM hypriot/rpi-alpine-scratch:v3.4
MAINTAINER Heiko Paland <paland.heiko@gmail.com>

ENV ELABFTW_VERSION 1.2.6

#install glibc https://github.com/chrisanthropic/docker-alpine-rpi-glibc/blob/master/Dockerfile

RUN apk upgrade --update && \
    apk add curl && \
    curl -Lo glibc-2.23-r3.apk https://github.com/chrisanthropic/docker-alpine-rpi-glibc-builder/releases/download/0.0.1/glibc-2.23-r3.apk && \
    curl -Lo glibc-bin-2.23-r3.apk https://github.com/chrisanthropic/docker-alpine-rpi-glibc-builder/releases/download/0.0.1/glibc-bin-2.23-r3.apk && \
    curl -Lo glibc-i18n-2.23-r3.apk https://github.com/chrisanthropic/docker-alpine-rpi-glibc-builder/releases/download/0.0.1/glibc-i18n-2.23-r3.apk && \
    apk add --allow-untrusted *.apk && \
    rm *.apk

#install java 8 https://github.com/chrisanthropic/docker-alpine-rpi-java8/blob/master/Dockerfile
# Java Version and other ENV
ENV JAVA_VERSION_MAJOR=8 \
    JAVA_VERSION_MINOR=91 \
    JAVA_VERSION_BUILD=14 \
    JAVA_PACKAGE=jdk \
    JAVA_HOME=/usr/lib/jvm/default-jvm \
    PATH=${PATH}:/opt/jdk/bin

# do all in one step
RUN apk upgrade --update && \
    apk add --update curl ca-certificates bash && \
    mkdir /opt && \
    curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" -o /tmp/java.tar.gz \
        http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-arm32-vfp-hflt.tar.gz && \
    gunzip /tmp/java.tar.gz && \
    tar -C /opt -xf /tmp/java.tar && \
    apk del glibc-i18n curl && \
    ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk && \
    cd /opt/jdk/ && ln -s ./jre/bin ./bin && \
    rm -rf /opt/jdk/jre/plugin \
           /opt/jdk/jre/bin/javaws \
           /opt/jdk/jre/bin/jjs \
           /opt/jdk/jre/bin/keytool \
           /opt/jdk/jre/bin/orbd \
           /opt/jdk/jre/bin/pack200 \
           /opt/jdk/jre/bin/policytool \
           /opt/jdk/jre/bin/rmid \
           /opt/jdk/jre/bin/rmiregistry \
           /opt/jdk/jre/bin/servertool \
           /opt/jdk/jre/bin/tnameserv \
           /opt/jdk/jre/bin/unpack200 \
           /opt/jdk/jre/lib/javaws.jar \
           /opt/jdk/jre/lib/deploy* \
           /opt/jdk/jre/lib/desktop \
           /opt/jdk/jre/lib/*javafx* \
           /opt/jdk/jre/lib/*jfx* \
           /opt/jdk/jre/lib/amd64/libdecora_sse.so \
           /opt/jdk/jre/lib/amd64/libprism_*.so \
           /opt/jdk/jre/lib/amd64/libfxplugins.so \
           /opt/jdk/jre/lib/amd64/libglass.so \
           /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
           /opt/jdk/jre/lib/amd64/libjavafx*.so \
           /opt/jdk/jre/lib/amd64/libjfx*.so \
           /opt/jdk/jre/lib/ext/jfxrt.jar \
           /opt/jdk/jre/lib/ext/nashorn.jar \
           /opt/jdk/jre/lib/oblique-fonts \
           /opt/jdk/jre/lib/plugin.jar \
           /tmp/* /var/cache/apk/* && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf

# enable testing repo to get php7
RUN echo http://dl-4.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

# install nginx and php-fpm
RUN apk add --update nginx openssl php7 php7-openssl php7-pdo_mysql php7-fpm php7-gd php7-curl php7-zip php7-zlib php7-json php7-gettext php7-session php7-mbstring git supervisor && rm -rf /var/cache/apk/*

# get latest stable version of elabftw
RUN git clone --depth 1 -b $ELABFTW_VERSION https://github.com/elabftw/elabftw.git /elabftw && chown -R nginx:nginx /elabftw && chmod -R u+x /elabftw

# only HTTPS
EXPOSE 443

# add files
COPY ./src/nginx/ /etc/nginx/
COPY ./src/supervisord.conf /etc/supervisord.conf
COPY ./src/run.sh /run.sh

# start
ENTRYPOINT exec /run.sh

# define mountable directories
VOLUME /elabftw/uploads
VOLUME /ssl
