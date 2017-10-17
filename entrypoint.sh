#!/bin/bash

VCL="default.vcl"

ALLOWED_HOSTS_CHECK=''
NORMALIZED_HOST=
for host in ${ALLOWED_HOSTS}; do
  if [[ ! $NORMALIZED_HOST ]]; then
    NORMALIZED_HOST=${host}
  fi
  ALLOWED_HOSTS_CHECK+="req.http.host == \"$host\" || "
done

TRIM=$(( ${#ALLOWED_HOSTS_CHECK} - 4 ))
export ALLOWED_HOSTS_CHECK=`echo ${ALLOWED_HOSTS_CHECK} | cut -c -${TRIM}`
export NORMALIZED_HOST=${NORMALIZED_HOST}

envsubst < /etc/varnish/default.template > /etc/varnish/default.vcl

# Start varnish and log
varnishd -f /etc/varnish/${VCL} -s malloc,100M -a 0.0.0.0:${VARNISH_PORT}
sleep 1
varnishlog
