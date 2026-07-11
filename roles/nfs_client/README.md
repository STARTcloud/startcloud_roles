# Ansible Role: nfs_client

Installs NFS client utilities and mounts remote NFS shares (writes `/etc/fstab`
so mounts survive a rebuild/reboot). Companion to the `nfs` (server) role.

## Requirements

None. Network reachability to the NFS server is assumed. Mount points that live
under another mount (e.g. an extra disk at `/local`) require that disk to be
mounted first — order this role after `disks` in your play.

## Role Variables

Available variables are listed below, along with default values (see
`defaults/main.yml`):

    nfs_client_mounts: []

A list of NFS shares to mount. Empty by default (no-op). Nothing is hard-coded
in the role — supply the values from `Hosts.yml`. Each item:

| Key      | Required | Default            | Description                            |
|----------|----------|--------------------|----------------------------------------|
| `src`    | yes      | —                  | `server:/export/path`                  |
| `path`   | yes      | —                  | Local mount point (created if absent)  |
| `fstype` | no       | `nfs`              | Filesystem type                        |
| `opts`   | no       | `defaults,_netdev` | Mount options (`_netdev` = wait net)   |
| `state`  | no       | `mounted`          | `ansible.builtin.mount` state          |

## Example (Hosts.yml)

    - name: startcloud.startcloud_roles.nfs_client
      vars:
        run_tasks: true
        nfs_client_mounts:
          - src: "nfs-server.example.com:/export/share"
            path: "/local/share"

## Dependencies

None.

## License

GPL-2.0-or-later
