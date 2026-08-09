# disks

Ansible role `disks` for the `startcloud.startcloud_roles` collection.

Expands the root partition/filesystem (plain or LUKS-encrypted) and formats/mounts additional disks declared in the host's `disks` structure. Dispatches to OS-specific tasks for Debian, OmniOS/illumos, and Windows.

## Dedicated data storage (Debian)

When `storage_device` names an attached block device, the role partitions it (guarded — never touches a mounted device, a whole-disk filesystem, or an existing data partition), formats it when blank, mounts it by UUID with `nofail`, creates `storage_subdirs` on the real mount, bind-mounts them into their target paths, and installs `RequiresMountsFor` systemd drop-ins for each entry in `storage_services` so those services refuse to start without their data mounts. With `storage_device` empty (the default) all of this is skipped, so the same configuration is safe on hosts without a data disk.

See `meta/argument_specs.yml` for all options.
