# Ansible Role: Composer

Installs Composer, the PHP dependency manager, on any Linux or UNIX system. The installer
is downloaded with its published SHA-384 signature verified, run with the configured
branch or version, and the resulting binary moved to a globally-accessible location.
Global packages, PATH entries, and a GitHub OAuth token can optionally be managed.

## Requirements

- `php` (version 5.4+) should be installed and working (the
  `startcloud.startcloud_roles.php` role can install it).
- `git` should be installed and working.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    composer_path: /usr/local/bin/composer

The path where composer will be installed and available to your system. Should be in
your user's `$PATH` so you can run commands simply with `composer` instead of the full
path.

    composer_keep_updated: false

Set this to `true` to update Composer to the latest release every time the playbook is
run. Mutually exclusive with `composer_version` — the role fails if both are set.

    composer_version: ''

Install a specific release of Composer, e.g. `composer_version: '1.0.0-alpha11'`. If left
empty, the latest version for the configured branch is installed.

    composer_version_branch: '--2'

Which major branch of Composer to use. To stay on Composer 1, set
`composer_version_branch: ''` and `composer_version: '1.10.12'`.

    composer_home_path: '~/.composer'
    composer_home_owner: root
    composer_home_group: root

The `COMPOSER_HOME` path and directory ownership; this is the directory where global
packages will be installed.

    composer_global_packages: []

A list of packages to install globally (using `composer global require`). Add a dict with
the `name` of the package and an optional `release`, e.g.
`- { name: phpunit/phpunit, release: "4.7.*" }`. The release defaults to `@stable`.

    composer_add_to_path: true

If `true`, and if there are any configured `composer_global_packages`, the `vendor/bin`
directory inside `composer_home_path` is added to the system's default `$PATH` (for all
users) via `/etc/profile.d/composer.sh`.

    composer_add_project_to_path: false
    composer_project_path: /path/to/project/vendor/bin

If `composer_add_project_to_path` is `true`, `composer_project_path` is prepended to the
system's default `$PATH` (for all users) via `/etc/profile.d/composer-project.sh`.

    composer_github_oauth_token: ''

GitHub OAuth token, written to `auth.json` in the composer home directory. Used to avoid
GitHub API rate limiting errors when building applications with Composer.

    php_executable: php

The executable name or full path of the PHP executable used to run the installer and
self-update.

## Dependencies

None (but make sure PHP is installed; the `startcloud.startcloud_roles.php` role is
recommended).

## Example Playbook

    - hosts: servers
      roles:
        - startcloud.startcloud_roles.composer

After the playbook runs, `composer` will be placed in `/usr/local/bin/composer` (this
location is configurable), and will be accessible via normal system accounts.

## License

GPL-2.0-or-later
