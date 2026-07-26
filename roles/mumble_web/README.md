# mumble_web

Ansible role `mumble_web` for the `startcloud.startcloud_roles` collection.

Deploys [mumble-web](https://github.com/Johni0702/mumble-web), a browser-based Mumble client, as a Docker container.

## Deployment modes

### Default: bundled websockify (no proxy)

`rankenstein/mumble-web:latest` bundles [websockify](https://github.com/novnc/websockify) and serves the client on
container port `8080` (its image metadata still says `EXPOSE 80`, which is stale — the server logs `Listen on :8080`).
It tunnels the Mumble control and voice stream over WebSocket straight to a murmur server, so no second container is
needed. `MUMBLE_SERVER` is set to `mumble_web_server_host:mumble_web_server_port`.

`mumble_web_server_host` has **no default** and the role fails when it is empty. There is no honest default: a loopback
address inside the client container is the container itself, never the murmur host.

```yaml
- role: startcloud.startcloud_roles.mumble_web
  vars:
    mumble_web_server_host: mumble.example.com
```

### Opt-in: mumble-web-proxy (WebRTC)

[mumble-web-proxy](https://github.com/johni0702/mumble-web-proxy) bridges browser WebSocket/WebRTC to murmur, which
gives UDP voice instead of a TCP tunnel. It is **off by default** because upstream publishes **no official container
image** — its README states the proxy "must be built from source", there is no `johni0702` image on Docker Hub or
GHCR, and the third-party rebuilds on Docker Hub are unaudited. `mumble_web_proxy_image` therefore has no default
either, and the role fails if the proxy is enabled without one.

WebRTC mode also needs a WebRTC-capable mumble-web build in `mumble_web_image`; the bundled-websockify default image
cannot talk to the proxy.

```yaml
- role: startcloud.startcloud_roles.mumble_web
  vars:
    mumble_web_server_host: mumble.example.com
    mumble_web_proxy_enabled: true
    mumble_web_proxy_image: registry.example.com/mumble-web-proxy:1.0
    mumble_web_image: registry.example.com/mumble-web-webrtc:latest
```

## Variables

See `meta/argument_specs.yml` for the full, validated list of variables and their defaults.
