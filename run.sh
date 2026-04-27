#!/usr/bin/env bash

set -e

CNT_NAME="tailsocks"
HOST=127.0.0.1
PORT=8888
HOSTNAME="$CNT_NAME"
BACKGROUND=""
REBUILD=0

# cd into the directory the script lives
cd "$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )" || exit 1

usage() {
  echo "Usage: $(basename "$0") [-h <host>] [-p <port>] [-n <hostname>] [-d] [-b]
    -h <host>        set the listening address of the SOCKS proxy (on the host)
    -p <port>        set the listening port of the SOCKS proxy (on the host)
    -n <hostname>    set the container hostname
    -d               start the container in the background (no interactive shell)
    -b               rebuild the container" 1>&2
    exit 1
}

while getopts "h:p:n:db" opt; do
  case "${opt}" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    n) HOSTNAME="$OPTARG" ;;
    d) BACKGROUND="d" ;;
    b) REBUILD=1 ;;
    *) usage ;;
  esac
done

if [ "$REBUILD" != "0" ]; then
  docker build -t "$CNT_NAME" .
fi

docker run "-ti$BACKGROUND" \
   --mount type=bind,source="$(realpath .)/statedir",target=/var/lib/tailscale/ \
   --hostname="$HOSTNAME" \
   --cap-add=NET_ADMIN \
   --cap-add=NET_RAW \
   --sysctl net.ipv4.conf.all.rp_filter=2 \
   --device=/dev/net/tun \
   -p "$HOST:$PORT":1080 \
   "$CNT_NAME"
