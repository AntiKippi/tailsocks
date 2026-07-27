#!/usr/bin/env bash

set -e


LOCK_FILE="tailsocks.lock"

CNT_NAME="tailsocks"
HOST="127.0.0.1"
PORT=8888
HOSTNAME="$CNT_NAME"
BACKGROUND=""
BUILD=0
CLEANUP=0


# Read and validate the container UUID saved in the lock file
function read_lock() {
  UUID_PATTERN='^\{?[A-Z0-9a-z]{8}-[A-Z0-9a-z]{4}-[A-Z0-9a-z]{4}-[A-Z0-9a-z]{4}-[A-Z0-9a-z]{12}\}?$'
  CNT_UUID="$(cat "$LOCK_FILE")"
  if [[ ! "$CNT_UUID" =~ $UUID_PATTERN ]]; then
    echo "ERROR: Could not parse container UUID" >&2
    exit 1
  fi

  # Return the UUID saved in the lock
  echo "$CNT_UUID"
}

# Perform the cleanup of the old container with UUID in $1
function clean_lock() {
  CNT_UUID=$1
  UNIQ_CNT_NAME="${CNT_NAME}_${CNT_UUID}"
  docker rm -f "$UNIQ_CNT_NAME" > /dev/null
  rm -f "$LOCK_FILE"
}


# cd into the directory the script lives
cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit 1

usage() {
  echo "Usage: $(basename "$0") [-h <host>] [-p <port>] [-n <hostname>] [-d] [-c] [-b]
    -h <host>        set the listening address of the SOCKS proxy (on the host)
    -p <port>        set the listening port of the SOCKS proxy (on the host)
    -n <hostname>    set the container hostname
    -d               start the container in the background (no interactive shell)
    -c               clean up the currect container before starting
    -b               rebuild the container" >&2
  exit 1
}

# Parse the command line arguments
while getopts "h:p:n:dcb" opt; do
  case "${opt}" in
    h) HOST="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    n) HOSTNAME="$OPTARG" ;;
    d) BACKGROUND="d" ;;
    c) CLEANUP=1 ;;
    b) BUILD=1 ;;
    *) usage ;;
  esac
done

# Proceed with cleanup handling if the lock file exists
if [ -e "$LOCK_FILE" ]; then
  # If a lock exists, but the cleanup option was not given we cannot proceed
  if [ "$CLEANUP" != "1" ]; then
    echo "ERROR: Container lock exists, old container must be cleaned up (-c)" >&2
    exit 1
  fi

  CNT_UUID="$(read_lock)"
  clean_lock "$CNT_UUID"
fi

# Always build the container if it has not been build before
if [ -z "$(docker images -q "$CNT_NAME" 2> /dev/null)" ]; then
  BUILD=1
fi

# (Re)build the container if necessary
if [ "$BUILD" != "0" ]; then
  docker build -t "$CNT_NAME" .
fi

# Generate a UUID for the current container, save it in the lock file
CNT_UUID="$(uuidgen -r)"
UNIQ_CNT_NAME="${CNT_NAME}_${CNT_UUID}"
echo "$CNT_UUID" > "$LOCK_FILE"

# Run the container
docker run "-it$BACKGROUND" \
   --name "$UNIQ_CNT_NAME" \
   --mount type=bind,source="$(realpath .)/statedir",target=/var/lib/tailscale/ \
   --hostname="$HOSTNAME" \
   --cap-add=NET_ADMIN \
   --cap-add=NET_RAW \
   --sysctl net.ipv4.conf.all.rp_filter=2 \
   --device=/dev/net/tun \
   -p "$HOST:$PORT":1080 \
   "$CNT_NAME"

# Automatically clean up after docker exit if not started in background mode
if [ -z "$BACKGROUND" ]; then
  clean_lock "$CNT_UUID"
fi
