# package_repository_server

Ansible role `package_repository_server` for the `startcloud.startcloud_roles` collection.

Builds and serves OS package repositories — OmniOS IPS pkg server instances
(base/core/extra/public/private) and the STARTcloud Debian package server
(`debian.startcloud.com`): a signed public APT repository, a nightly Debian
mirror and an mTLS client-certificate-gated private APT repository, all served
by **one** nginx vhost that separates them by path.

## How it dispatches

`tasks/main.yml` picks the OS key (`omnios` on OmniOS, otherwise
`ansible_os_family | lower`) and always runs `<os>-base.yml`.

On **OmniOS** one archive is published per include of the role, selected by
`pkg_server.type`:

- `core` / `extra` — mirrors the archive from `repo_url` via pkgrecv
- `public` / `private` — clones `repo_url` and builds via buildctl

`storage_disk` and the full `pkg_server` structure (omnios_release, archive,
name, port, repo_url, description, type) are supplied by the calling play.

On **Debian** every tree is served from the same vhost, so the trees are
toggles rather than mutually exclusive types — a single include of the role
provisions the whole server:

- always — `public/debian`, built and signed from the deb the debian_packager
  role produces, and consumed back off its own URL as an end-to-end proof
- `pkg_server_public_enabled` (default `true`) — public landing page and
  stylesheet under `public/`
- `pkg_server_mirror_enabled` (default `false`) — debmirror into
  `mirror/debian` plus its nightly cron
- `pkg_server_private_enabled` (default `false`) — client-certificate CA,
  `private/debian`, the client minting tool, and the mTLS directives in the
  vhost

## Served layout (production: debian.startcloud.com)

```text
https://debian.startcloud.com/          302 → /public/
                             /public/   public landing page and the signed APT repository
                             /public/debian/   deb [signed-by=…] https://debian.startcloud.com/public/debian/ stable main
                             /mirror/   Debian mirror, autoindex
                             /private/  mTLS-gated APT repository (403 without a verified client certificate)
                             /certs/    the requesting certificate's own bundle, aliased by its CN
```

Anything else under the root is refused with 404 — the CA, the client keys, the
PGP key pair, the staging tree and the scripts all live beside the published
trees:

```text
/local/
├── ca/                      # private-repo client-certificate CA (ca.key, ca.crt)
├── clients/<name>/certs/    # generated client certs (key, crt, p12, pem, README) — served at /certs/
├── generate_client_cert.sh  # mint a client cert: ./generate_client_cert.sh <name> [password]
├── generate-release.sh      # regenerate a Release file: cd <repo>/dists/<suite> && /local/generate-release.sh <suite> > Release
├── mirror/                  # debmirror target, served at /mirror/
├── mirror_deb_repo.sh       # nightly debmirror sync (cron, 02:00)
├── pgp/                     # repository PGP signing key pair (+ its GNUPGHOME)
├── private/                 # mTLS-gated repo, served at /private/
├── public/                  # public repo and landing page, served at /public/
└── staging/                 # where the repository indexes are rendered before publication
```

`pkg_server_legacy_domains` is appended to `server_name`, so the retired
`public.`/`private.`/`mirror.` hostnames keep resolving to the same vhost while
consumers migrate to the path scheme.

TLS certificates are issued by certbot outside this role; set
`pkg_server_ssl_enabled: false` on hosts that don't have them yet to render a
single plain port-80 server block instead of the redirect + TLS pair.

A FreeBSD variant (poudriere/pkg repo) is planned but not yet implemented.
