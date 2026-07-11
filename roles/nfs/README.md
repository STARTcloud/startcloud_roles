# Ansible Role: NFS

Installs NFS server utilities on Debian/Ubuntu or RHEL-family systems, creates the
export directories, renders `/etc/exports`, and ensures the NFS server daemon is running.
Export changes trigger an `exportfs -ra` reload.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    nfs_exports: []

A list of export lines placed verbatim in `/etc/exports`. The first field of each entry
is also created as a directory (mode 0755). Simple example:
`nfs_exports: [ "/home/public    *(rw,sync,no_root_squash)" ]`.

    nfs_rpcbind_state: started
    nfs_rpcbind_enabled: true

(RHEL-family only) The state of the `rpcbind` service and whether it should be enabled
at boot.

The NFS server daemon name is resolved per OS from `vars/` (`nfs_server_daemon`:
`nfs-kernel-server` on Debian, `nfs-server` on RHEL/Fedora).

## Dependencies

None.

## Example Playbook

    - hosts: nfs-servers
      roles:
        - startcloud.startcloud_roles.nfs

## License

GPL-2.0-or-later
