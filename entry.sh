#!/usr/bin/env sh

set -e

# Activate tailscale connection
tailscaled --state=/var/lib/tailscale/tailscaled.state > /var/log/tailscaled.out 2> /var/log/tailscaled.err &

# Start SOCKS5 server
microsocks -p 1080 > /var/log/microsocks.out 2> /var/log/microsocks.err &

# Give user interactive prompt
sh -i
