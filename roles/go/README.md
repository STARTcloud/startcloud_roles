# Ansible Role: Go

Installs Go (the language) on Linux from the official Google binary tarball. An existing
`/usr/local/go` is replaced when its version doesn't match `go_version`; the download is
checksum-verified, extracted to `/usr/local`, and the Go bin directory is added to the
system-wide `$PATH` via `/etc/profile.d/go-path.sh`.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    go_version: "1.17.3"
    go_platform: linux
    go_arch: amd64

Version, platform, and architecture to use when downloading Go.

    go_tarball: go{{ go_version }}.{{ go_platform }}-{{ go_arch }}.tar.gz
    go_download_url: https://dl.google.com/go/{{ go_tarball }}

These two variables build the download URL when installing Go.

    go_checksum: '550f9845451c0c94be679faf116291e7807a8d78b43149f9506c1b15eb89008c'

SHA256 checksum of the Go download. If changing the version, platform, or architecture,
update this checksum too.

## Dependencies

None.

## Example Playbook

    - hosts: myserver
      roles:
        - startcloud.startcloud_roles.go

## License

GPL-2.0-or-later
