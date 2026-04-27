#!/usr/bin/env bash

set -e

CNT_NAME="tailsocks"
HOST="127.0.0.1"
PORT=8888
HOSTNAME="$CNT_NAME"
BACKGROUND=""
BUILD=0

# cd into the directory the script lives
cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit 1

usage() {
  echo "Usage: $(basename "$0") [-h <host>] [-p <port>] [-n <hostname>] [-d] [-b]
    -h <host>        set the listening address of the SOCKS proxy (on the host)
    -p <port>        set the listening port of the SOCKS proxy (on the host)
    -n <hostname>    set the container hostname
    -d               start the container in the background (no interactive shell)
    -b               rebuild the container" 1>&2
    exit 1
}

# Parse the command line arguments
while getopts "h:p:n:db" opt; do
  case "${opt}" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    n) HOSTNAME="$OPTARG" ;;
    d) BACKGROUND="d" ;;
    b) BUILD=1 ;;
    *) usage ;;
  esac
done

# Always build the container if it has not been build before
if [ -z "$(docker images -q "$CNT_NAME" 2> /dev/null)" ]; then
  BUILD=1
fi

# (Re)build the container if necessary
if [ "$BUILD" != "0" ]; then
  docker build -t "$CNT_NAME" .
fi

# Run the container
docker run "-it$BACKGROUND" \
   --mount type=bind,source="$(realpath .)/statedir",target=/var/lib/tailscale/ \
   --hostname="$HOSTNAME" \
   --cap-add=NET_ADMIN \
   --cap-add=NET_RAW \
   --sysctl net.ipv4.conf.all.rp_filter=2 \
   --device=/dev/net/tun \
   -p "$HOST:$PORT":1080 \
   "$CNT_NAME"
