FROM buildpack-deps:xenial

MAINTAINER Derrick Petzold "varnish@petzold.io"

RUN apt-get update -qq && \
  apt-get -yqq install gettext-base python3-docutils && \
  apt-get -yqq clean

ENV VARNISH_VERSION 4.1.8

VOLUME ["/var/lib/varnish", "/etc/varnish"]

RUN set -ex \
  && curl -fSL https://varnish-cache.org/_downloads/varnish-$VARNISH_VERSION.tgz -o varnish.tar.gz \
  && tar xf varnish.tar.gz \
  && rm varnish.tar.gz \
  && cd varnish-$VARNISH_VERSION \
  && sh autogen.sh \
  && sh configure \
  && make \
  && make install \
  && cd .. \
  && rm -r varnish-$VARNISH_VERSION \
  && echo "/usr/local/lib/varnish/vmods" >> /etc/ld.so.conf.d/varnish.conf \
  && ldconfig

EXPOSE 80

ADD entrypoint.sh /entrypoint.sh
ADD default.vcl /etc/varnish/default.template

ENTRYPOINT ["/entrypoint.sh"]
