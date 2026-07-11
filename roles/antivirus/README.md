# Ansible Role: Antivirus

Installs and configures antivirus software on Linux and Windows guests. Two engines are
supported, each gated by its own variable: ClamAV (Debian/Ubuntu and RHEL-family packages,
ClamWin via Chocolatey on Windows) and Sophos (vendor installer on Linux and Windows).

## Requirements

- Windows ClamAV installs use Chocolatey (`chocolatey.chocolatey` collection).
- Sophos installs download the vendor setup executable/script at provision time, so the
  guest needs outbound HTTPS access to the configured URL.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`
and the OS files under `vars/`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    install_clamav: false
    install_sophos: false

Which engines to install. Both default to off; the vendor variable files
(`vars/STARTcloud.yml`, `vars/Prominic.yml`, loaded when `vendor` is set) enable ClamAV.

    sophos_linux_url: ''
    sophos_windows_url: ''

Override the Sophos installer download locations.

    clamav_daemon_localsocket: /var/run/clamav/clamd.ctl

Local socket path the ClamAV daemon listens on (RHEL systems override this in
`vars/RedHat.yml`).

    clamav_daemon_configuration_changes:
      - regexp: "^.*Example$"
        state: absent
      - regexp: "^.*LocalSocket .*$"
        line: "LocalSocket {{ clamav_daemon_localsocket }}"

Line edits applied to the ClamAV daemon configuration. At minimum the `Example` line must
be removed and a socket opened for the daemon to start.

    clamav_daemon_state: started
    clamav_daemon_enabled: true
    clamav_freshclam_daemon_state: started
    clamav_freshclam_daemon_enabled: true

Service state and boot-enablement for the ClamAV and freshclam daemons.

Package lists, daemon names, and configuration paths are resolved per OS family from
`vars/Debian.yml` and `vars/RedHat.yml` (`clamav_packages`, `clamav_daemon`,
`clamav_freshclam_daemon`, `clamav_daemon_config_path`,
`clamav_freshclam_daemon_config_path`) and can be overridden by the calling play.

After ClamAV package changes, freshclam runs immediately (via handler flush) so virus
definitions exist before the daemons are started. On RHEL systems a
`clamd-freshclam.service` unit is templated in to run freshclam as a daemon.

## Dependencies

None.

## Example Playbook

    - hosts: all
      become: true
      vars:
        vendor: STARTcloud
      roles:
        - startcloud.startcloud_roles.antivirus

## License

GPL-2.0-or-later
