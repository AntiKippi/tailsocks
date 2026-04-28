# tailsocks
A lightweight Docker container that provides SOCKS5 access to a Tailscale network with minimal resource overhead. No bloat, no BS - just a simple "Tailscale-to-SOCKS converter".

## Background
For work related things I recently needed Tailscale to access internal services and use an Exit Node for specific tasks. And I came to quite dislike how deep Tailscale interferes with my system. Especially the Exit Node feature is quite annoying since it forces ALL of my traffic over the Exit Node, whereas I just need it for a _very_ specific subset of hosts. But also MagicDNS fiddling with my DNS settings is something I simply do not want.

One day I had the idea that I could confine Tailscale in a container and use a SOCKS proxy to access the Tailscale network instead, which lead to this weekend project.

## Usage
```bash
$ git clone https://github.com/AntiKippi/tailsocks
$ tailsocks/run.sh
```

Executing `run.sh` starts a SOCKS5 proxy on `127.0.0.1:8888` and provides an interactive shell. From this shell, you can use the standard [Tailscale CLI](https://tailscale.com/docs/reference/tailscale-cli) to configure your connection. For example, to connect to a Tailscale network and configure an Exit Node:

```bash
# tailscale up
# tailscale set --exit-node-allow-lan-access --exit-node=<exit-node-ip> 
```

The state is persisted (in the `statedir` directory), so the settings and active connections will survive a restart of the container.

### Docker Compose
For convenience, a Docker Compose file is provided to start the container using `docker compose up`. Note that this method does not provide an interactive shell. To configure Tailscale when using Compose, use:
```bash
$ docker compose exec tailsocks sh
```

### Customization
You can customize several parameters, such as the proxy host and port, the container hostname, and whether the container should start interactively. See `./run.sh --help` for more information.

When using Docker Compose, you can configure the proxy host, port, and container hostname using the `TS_HOST`, `TS_PORT`, and `TS_HOSTNAME` environment variables, respectively.

To configure the SOCKS server (e.g. to add authentication) please just modify the `microsocks` command-line arguments in `entry.sh`. Refer to `microsocks --help` for available options.

## Maintenance
This project will be maintained (as in bugs get fixed) as long as it is useful to me. I do not intend to add new features, but feel free to submit a pull request.
