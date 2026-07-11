# Ansible Role: Exim

Installs the Exim mail transfer agent on Debian/Ubuntu or RHEL-family systems and applies
basic configuration, then ensures the daemon is running and enabled.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    exim_dc_eximconfig_configtype: internet

(Debian/Ubuntu only) Main configuration type. Should be `internet` for public mail
sending, or `local` if mail should only be delivered locally. See the Exim documentation
for other options.

    exim_dc_localdelivery: mail_spool

(Debian/Ubuntu only) Default transport for local mail delivery.

    exim_primary_hostname: ""

Force a primary server hostname for Exim. Usually unneeded, but if Exim can't reliably
determine the FQDN of the server, set this to ensure the correct hostname is used.

Package name, daemon name, and configuration file path are resolved per OS family from
`vars/Debian.yml` and `vars/RedHat.yml` (`exim_package`, `exim_daemon`,
`exim_configuration_file`).

## Dependencies

None.

## Example Playbook

    - hosts: servers
      roles:
        - startcloud.startcloud_roles.exim

## License

GPL-2.0-or-later
