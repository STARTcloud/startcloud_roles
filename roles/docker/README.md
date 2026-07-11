# Ansible Role: Docker

Installs Docker CE on Debian/Ubuntu or RHEL-family systems from the official Docker
repository, configures the daemon, optionally installs Docker Compose (as a plugin
and/or standalone binary), and manages membership of the `docker` group.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    docker_edition: 'ce'
    docker_packages:
      - "docker-{{ docker_edition }}"
      - "docker-{{ docker_edition }}-cli"
      - "docker-{{ docker_edition }}-rootless-extras"
      - "containerd.io"
      - docker-buildx-plugin
    docker_packages_state: present

The `docker_edition` should be either `ce` (Community Edition) or `ee` (Enterprise
Edition). A specific version can be pinned using the distribution-specific format:
`docker-{{ docker_edition }}-<VERSION>` on RHEL, `docker-{{ docker_edition }}=<VERSION>`
on Debian/Ubuntu (apply it to every package in the list). Set `docker_packages_state` to
`present`, `absent`, or `latest` as needed — the daemon restarts automatically if the
package is updated (handlers are flushed at that point in the play).

    docker_service_manage: true
    docker_service_state: started
    docker_service_enabled: true
    docker_restart_handler_state: restarted

State of the `docker` service and whether it starts on boot. Set
`docker_service_manage: false` when installing Docker inside a container without
systemd/sysvinit.

    docker_install_compose_plugin: true
    docker_compose_package: docker-compose-plugin
    docker_compose_package_state: present

Docker Compose plugin options (used as `docker compose`).

    docker_install_compose: false
    docker_compose_version: "v2.30.3"
    docker_compose_arch: "{{ ansible_architecture }}"
    docker_compose_path: /usr/local/bin/docker-compose

Standalone `docker-compose` binary options. When enabled, an existing binary of a
different version is replaced.

    docker_add_repo: true

Whether this role adds the official Docker repository. Set to `false` to use your
distribution's packages or manage the repository yourself.

    docker_repo_url: https://download.docker.com/linux

The main Docker repo URL, common between Debian and RHEL systems.

    docker_apt_release_channel: stable
    docker_apt_arch: "{{ 'arm64' if ansible_architecture == 'aarch64' else 'amd64' }}"
    docker_apt_repository: "deb [arch={{ docker_apt_arch }} {{ docker_trusted_key }}] {{ docker_repo_url }}/{{ docker_apt_ansible_distribution | lower }} {{ ansible_distribution_release }} {{ docker_apt_release_channel }}"
    docker_apt_ignore_key_error: true
    docker_apt_gpg_key: "{{ docker_repo_url }}/{{ docker_apt_ansible_distribution | lower }}/gpg"
    docker_apt_gpg_key_checksum: "sha256:1500c1f56fa9e26b9b8f42452a553675796ade0807cdce11975eb98170b3a570"
    docker_apt_filename: "docker"

(Debian/Ubuntu only.) Switch the channel to `nightly` for nightly releases. The GPG key
URL/checksum and repository line can be pointed at a mirror; `docker_apt_filename`
controls the sources list filename. Pop!_OS and Linux Mint are mapped to the Ubuntu
repository automatically.

    docker_yum_repo_url: "{{ docker_repo_url }}/{{ (ansible_distribution == 'Fedora') | ternary('fedora','centos') }}/docker-{{ docker_edition }}.repo"
    docker_yum_repo_enable_nightly: '0'
    docker_yum_repo_enable_test: '0'
    docker_yum_gpg_key: "{{ docker_repo_url }}/centos/gpg"

(RHEL-family only.) Enable the Nightly or Test repo by setting the respective vars to
`1`. On RHEL 8, `runc` is removed and `container-selinux`/`containerd.io` are ensured.

    docker_users: []

A list of system users to be added to the `docker` group (so they can use Docker on the
server). The SSH connection is reset afterwards so group membership applies immediately.

    docker_daemon_options: { "log-driver": "journald", "log-level": "warn", "debug": false, "default-address-pools": [{ "base": "172.17.0.0/24", "size": 28 }] }

Custom `dockerd` options, written as JSON to `/etc/docker/daemon.json`.

## Dependencies

None.

## Example Playbook

    - hosts: all
      roles:
        - startcloud.startcloud_roles.docker

## License

GPL-2.0-or-later
