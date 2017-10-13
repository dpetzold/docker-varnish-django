FROM buildpack-deps:xenial

MAINTAINER Derrick Petzold "varnish@petzold.io"

RUN apt-get update -qq && \
  apt-get -yqq install gettext-base python3-docutils && \
  apt-get -yqq clean

ENV VARNISH_VERSION 4.1.8

VOLUME ["/var/lib/varnish", "/etc/varnish"]

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
  && ldconfig \
  && git clone https://github.com/varnishcache/varnish-devicedetect.git \
  && cp varnish-devicedetect/devicedetect.vcl /etc/varnish \
  && rm -r varnish-devicedetect


ENV \
  VARNISH_BACKEND_IP=172.17.42.1 \
  VARNISH_BACKEND_PORT=80 \
  VARNISH_PORT=80

EXPOSE 80

ADD start.sh /start.sh
ADD default.vcl /etc/varnish/default.template
ADD named.vcl /etc/varnish/named.template

CMD ["/start.sh"]
