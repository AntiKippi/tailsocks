#!/usr/bin/env bash

set -e

CNT_NAME="tailsocks"

# cd into the directory the script lives
cd "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" || exit 1

docker build -t "$CNT_NAME" .
docker run -ti \
   --mount type=bind,source="$(realpath .)/statedir",target=/var/lib/tailscale/ \
   --hostname="$CNT_NAME" \
   --cap-add=NET_ADMIN \
   --cap-add=NET_RAW \
   --sysctl net.ipv4.conf.all.rp_filter=2 \
   --device=/dev/net/tun \
   -p 127.0.0.1:8888:1080 \
   "$CNT_NAME"
