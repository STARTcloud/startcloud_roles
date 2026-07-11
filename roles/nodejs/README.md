# Ansible Role: Node.js

Installs Node.js and npm on Debian/Ubuntu or RHEL-family systems from the NodeSource
repositories (signed-by keyring on Debian, RPM repo on EL), provisions a global npm
prefix, and optionally installs global packages or the dependencies of a `package.json`.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    nodejs_version: "22.x"

The NodeSource release line to install (e.g. `"20.x"`, `"22.x"`). Version lines follow
the NodeSource distributions repository.

    nodejs_install_npm_user: "{{ service_user | default('startcloud') }}"

The user for whom the npm packages will be installed; owns the global npm prefix.

    npm_config_prefix: "/usr/local/lib/npm"

The global installation directory. This should be writeable by
`nodejs_install_npm_user`.

    npm_config_unsafe_perm: "false"

Set to true to suppress the UID/GID switching when running package scripts. If set
explicitly to false, then installing as a non-root user will fail.

    nodejs_npm_global_packages: []

A list of npm packages with a `name` and (optional) `version` to be installed globally.
For example:

    nodejs_npm_global_packages:
      # Install a specific version of a package.
      - name: jslint
        version: 0.9.3
      # Install the latest stable release of a package.
      - name: node-sass
      # This shorthand syntax also works (same as previous example).
      - node-sass
      # Remove a package by setting state to 'absent'.
      - name: node-sass
        state: absent

    nodejs_package_json_path: ""

Set a path pointing to a particular `package.json` (e.g. `"/var/www/app/package.json"`).
This will install all of the defined packages globally using Ansible's `npm` module.

    nodejs_generate_etc_profile: "true"

By default the role creates `/etc/profile.d/npm.sh` exporting `PATH`,
`NPM_CONFIG_PREFIX`, and `NODE_PATH`. Set to `"false"` to handle those variables
yourself (e.g. for a per-user install).

## Dependencies

None.

## Example Playbook

    - hosts: utility
      vars:
        nodejs_npm_global_packages:
          - name: jslint
          - name: node-sass
      roles:
        - startcloud.startcloud_roles.nodejs

## License

GPL-2.0-or-later
