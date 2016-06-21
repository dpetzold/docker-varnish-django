FROM buildpack-deps:xenial

MAINTAINER Derrick Petzold "varnish@petzold.io"
ENV REFRESHED_AT 2016-07-10

RUN apt-get update -qq && \
  apt-get -yqq install gettext-base python3-docutils && \
  apt-get -yqq clean

ENV VARNISH_VERSION 4.1.3

RUN set -ex \
  && curl -fSL https://repo.varnish-cache.org/source/varnish-$VARNISH_VERSION.tar.gz -o varnish.tar.gz \
  && tar xf varnish.tar.gz \
  && rm varnish.tar.gz \
  && cd varnish-$VARNISH_VERSION \
  && sh autogen.sh \
  && sh configure \
  && make \
  && make install \
  && cd .. \
  && rm -r varnish-$VARNISH_VERSION \
  && git clone https://github.com/Dridi/libvmod-named.git \
  && cd libvmod-named \
  && ./autogen.sh \
  && ./configure \
  && make \
  && make install \
  && cd .. \
  && rm -r libvmod-named \
  && echo "/usr/local/lib/varnish/vmods" >> /etc/ld.so.conf.d/varnish.conf \
  && ldconfig

ENV \
  VARNISH_BACKEND_IP=172.17.42.1 \
  VARNISH_BACKEND_PORT=80 \
  VARNISH_PORT=80

EXPOSE 80

VOLUME ["/var/lib/varnish", "/etc/varnish"]

ADD start.sh /start.sh
ADD default.vcl /etc/varnish/default.template
ADD named.vcl /etc/varnish/named.template

CMD ["/start.sh"]
