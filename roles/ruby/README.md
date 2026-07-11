# Ansible Role: Ruby

Installs Ruby on Debian/Ubuntu or RHEL-family systems — from system packages by default,
or built from a source tarball — plus Bundler and any configured gems. The user RubyGems
bin directory is added to the global `$PATH` via `/etc/profile.d/rubygems.sh`.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    workspace: /root

The location where temporary files will be downloaded in preparation for a source build.

    ruby_install_bundler: true

Whether this role should install [Bundler](https://bundler.io/).

    ruby_install_gems: []

A list of Ruby gems to install. Each entry is either just the gem name (installs the
latest version) or a dictionary allowing `version` and `user_install` keys for the `gem`
module. The two syntaxes can be mixed:

    ruby_install_gems:
      - name: bundler
        version: '< 2'
        user_install: false
      - rake

    ruby_install_gems_user: "{{ ansible_user }}"

The user account under which the configured gems are installed.

    ruby_install_from_source: false

By default the role installs whatever Ruby version your system's package manager
provides. Set this to `true` (and adjust the three variables below) to build a specific
version from source instead. A version marker in `/var/cache/ansible/` skips the build
when the requested version is already installed.

    ruby_download_url: http://cache.ruby-lang.org/pub/ruby/3.0/ruby-3.0.0.tar.gz

The URL from which the Ruby source tarball is downloaded (source installs only).

    ruby_version: 3.0.0

The version of Ruby that will be built (source installs only).

    ruby_source_configure_command: ./configure --enable-shared

The `configure` command run during the source build.

    ruby_rubygems_package_name: rubygems

The name of the rubygems package. The default generally works; it is switched to
`rubygems-integration` automatically on Ubuntu Trusty (14.04).

## Dependencies

None.

## Example Playbook

    - hosts: server
      roles:
        - role: startcloud.startcloud_roles.ruby

## License

GPL-2.0-or-later
