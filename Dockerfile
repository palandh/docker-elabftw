# elabftw in docker, without sql
FROM hypriot/rpi-alpine-scratch:v3.4
MAINTAINER Heiko Paland <paland.heiko@gmail.com>

ENV ELABFTW_VERSION 1.2.6

#Since Java8 is tricky on RPi we will try with Java7 instead
#Solution via https://hub.docker.com/r/fnphat/rpi-alpine-java/
RUN apk update && \
    apk upgrade && \
    apk add openjdk7-jre --update-cache --repository http://nl.alpinelinux.org/alpine/v3.3/community && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*


# enable testing repo to get php7
RUN echo http://dl-4.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories

# install nginx and php-fpm
RUN apk add --update nginx openssl php7 php7-openssl php7-pdo_mysql php7-fpm php7-gd php7-curl php7-zip php7-zlib php7-json php7-gettext php7-session php7-mbstring git supervisor && rm -rf /var/cache/apk/*

# get latest stable version of elabftw
RUN git clone --depth 1 -b $ELABFTW_VERSION https://github.com/palndh/pilabftw.git /elabftw && chown -R nginx:nginx /elabftw && chmod -R u+x /elabftw

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
