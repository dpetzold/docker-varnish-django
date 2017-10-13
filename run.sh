#!/bin/bash

docker run \
  -e ALLOWED_HOSTS="petzold.io derrickpetzold.com" \
  -e ADMIN_URL="^admin/" \
  -e HEALTH_CHECK_URL="/200/" \
  -e VARNISH_NAMED_BACKEND=localhost \
  -it dpetzold/docker-varnish-django bash
