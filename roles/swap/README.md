# Ansible Role: Swap

Configures swap space on Linux: manages the swap file's fstab entry, creates the file at
the requested size (recreating it when the size changes), activates it with
mkswap/swapon, and sets `vm.swappiness`.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    swap_file_path: /swapfile

The location of the swap file on the server.

    swap_file_size_mb: '512'

How large (in mebibytes) to make the swap file. If an existing swap file's size differs,
it is disabled, removed, and recreated at this size.

    swap_swappiness: '60'

The `vm.swappiness` value to be configured in sysctl.

    swap_file_state: present

Set to `absent` to disable swap and remove the swap file.

    swap_file_create_command: "dd if=/dev/zero of={{ swap_file_path }} bs=1M count={{ swap_file_size_mb }}"

The command used to create the swap file. You could switch to `fallocate` to write the
swap file more quickly, though there may be inconsistencies if not writing the file with
`dd`.

    swap_test_mode: false

When true, the `swapon` step is skipped so the role can run in environments where swap
cannot actually be activated (e.g. containers).

## Dependencies

None.

## Example Playbook

    - hosts: all
      vars:
        swap_file_size_mb: '1024'
      roles:
        - startcloud.startcloud_roles.swap

## License

GPL-2.0-or-later
