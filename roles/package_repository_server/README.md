# package_repository_server

Ansible role `package_repository_server` for the `startcloud.startcloud_roles` collection.

Builds and serves OS package repositories — OmniOS IPS pkg server instances
(base/core/extra/public/private) and the STARTcloud Debian package server
(`packages.debian.startcloud.com`): a nightly Debian mirror, a public
PGP-signed APT repository, and an mTLS client-certificate-gated private APT
repository, all served by nginx from `pkg_server_base_dir` (default `/local`).

## How it dispatches

`tasks/main.yml` picks the OS key (`omnios` on OmniOS, otherwise
`ansible_os_family | lower`), always runs `<os>-base.yml`, then runs
`<os>-<type>.yml` when `pkg_server.type` is set to something other than
`base`:

| OS     | `pkg_server.type`    | What it does                                                        |
|--------|----------------------|---------------------------------------------------------------------|
| omnios | `core` / `extra`     | Mirrors the archive from `repo_url` via pkgrecv                     |
| omnios | `public` / `private` | Clones `repo_url` and builds via buildctl                           |
| debian | `mirror`             | debmirror nightly sync into `/local/mirror` + nginx vhost           |
| debian | `public`             | `/local/public` tree, PGP signing key, Release script + nginx vhost |
| debian | `private`            | `/local/private` tree, client-cert CA + tooling, mTLS nginx vhost   |

`storage_disk` and the full `pkg_server` structure (omnios_release, archive,
name, port, repo_url, description, type) are supplied by the calling play.
Include the role once per archive.

## Debian layout (production: packages.debian.startcloud.com)

```text
/local/
├── ca/                      # private-repo client-certificate CA (ca.key, ca.crt)
├── clients/<name>/          # generated client certs (key, crt, p12, pem, README)
├── generate_client_cert.sh  # mint a client cert: ./generate_client_cert.sh <name> [password]
├── generate-release.sh      # regenerate a Release file: cd <repo>/dists/<suite> && /local/generate-release.sh <suite> > Release
├── mirror/                  # debmirror target, served at mirror.debian.packages.startcloud.com
├── mirror_deb_repo.sh       # nightly debmirror sync (cron, 02:00)
├── pgp/                     # repository PGP signing key pair
├── private/                 # mTLS-gated repo, served at private.debian.packages.startcloud.com
└── public/                  # public repo, served at public.debian.packages.startcloud.com
```

TLS certificates are issued by certbot outside this role; set
`pkg_server_ssl_enabled: false` on hosts that don't have them yet to render
only the port-80 server blocks.

A FreeBSD variant (poudriere/pkg repo) is planned but not yet implemented.
