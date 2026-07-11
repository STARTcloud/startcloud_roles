# package_repository_server

Ansible role `package_repository_server` for the `startcloud.startcloud_roles` collection.

Builds and serves OS package repositories — OmniOS IPS pkg server instances
(base/core/extra/public/private) and a PGP-signed Debian APT repository.

## How it dispatches

`tasks/main.yml` picks the OS key (`omnios` on OmniOS, otherwise
`ansible_os_family | lower`), always runs `<os>-base.yml` (dataset + pkgrepo +
SMF instance on OmniOS, signed APT repo on Debian), then runs
`<os>-<type>.yml` when `pkg_server.type` is set to something other than
`base`:

| `pkg_server.type`    | What it does                                    |
|----------------------|-------------------------------------------------|
| `core` / `extra`     | Mirrors the archive from `repo_url` via pkgrecv |
| `public` / `private` | Clones `repo_url` and builds via buildctl       |

`storage_disk` and the full `pkg_server` structure (omnios_release, archive,
name, port, repo_url, description, type) are supplied by the calling play.
Include the role once per archive.

A FreeBSD variant (poudriere/pkg repo) is planned but not yet implemented
(`debian-public.yml` / `debian-private.yml` are placeholders as well).
