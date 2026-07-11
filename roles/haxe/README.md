# Ansible Role: Haxe

Installs a pinned Haxe release on Debian/Ubuntu — build dependencies, the Haxe
compiler from the official GitHub release tarball, Neko, haxelib setup, and the
configured Haxe libraries (including git-sourced dev libraries and optional
OpenFL setup).

## Requirements

Debian-family target with network access to github.com and lib.haxe.org.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    haxe_version: "4.3.6"

Haxe release version to download and install.

    haxe_home: "/opt/haxe/haxe-{{ haxe_version }}"

Base directory for the Haxe installation.

    haxelib_dir: "/opt/haxe/haxelib_default"

Directory used as the haxelib library store.

    haxe: "{{ haxe_home }}/haxe"
    haxelib: "{{ haxe_home }}/haxelib"

Paths to the haxe and haxelib binaries.

    install_neko: true

Whether Neko (required by Haxe) is part of the install.

    install_openfl: true

Run `haxelib run openfl setup` after the libraries are installed.

    additional_haxe_libraries:
      - feathersui-validators
      - lime
      - pako

Haxe libraries installed via `haxelib install`.

    additional_haxe_libraries_dev:
      - library: "mxhx-feathersui"
        repo: "https://github.com/mxhx-dev/mxhx-feathersui.git"
        branch: ""

Haxe libraries installed from git via `haxelib git` (library, repo, branch).

The install runs as `service_user` (falling back to the Ansible connection
user) and exposes the Haxe binaries by appending `haxe_home` to the PATH used
by the haxelib commands.

## Dependencies

None.

## Example Playbook

    - hosts: builders
      vars:
        haxe_version: "4.3.6"
        additional_haxe_libraries:
          - lime
          - pako
      roles:
        - startcloud.startcloud_roles.haxe

## License

GPL-2.0-or-later
