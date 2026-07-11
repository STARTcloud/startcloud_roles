# Ansible Role: PHP Versions

Selects a single PHP version for a host and prepares the system so the
`startcloud.startcloud_roles.php` role (or a similar role) installs exactly that version.
On Debian/Ubuntu it configures the Ondrej Sury repositories (PPA on Ubuntu, sury.org apt
repo on Debian) and purges the package sets of every other PHP version; on EL it selects
the matching Remi repositories and enables the `php:remi-*` DNF module on EL 8+.

The role also defines the version-specific variables consumed by the php role
(`php_packages`, `php_fpm_daemon`, `php_conf_paths`, extension module paths, and so on)
from its `vars/` files, so switching `php_version` is a one-variable change.

## Requirements

N/A

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    php_version: '8.2'

The PHP version to be installed. Any currently-supported PHP major version is a valid
option (e.g. `7.4`, `8.0`, `8.1`, or `8.2`).

    php_versions_install_recommends: false

(Debian/Ubuntu only) Whether to install recommended packages. Disabled by default
because enabling it often leads to multiple PHP versions being installed when using the
Sury repositories.

## Dependencies

- `startcloud.startcloud_roles.php` is a soft dependency — this role exists to feed it
  the `php_version`-specific variables and should run before it.

## Example Playbook

    - hosts: webservers
      become: true

      vars:
        php_version: '8.2'

      roles:
        - startcloud.startcloud_roles.php_versions
        - startcloud.startcloud_roles.php

## License

GPL-2.0-or-later
