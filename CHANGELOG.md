# Changelog

All notable changes to the `startcloud.startcloud_roles` collection are
documented here.

## [Unreleased]

### Added

- FreeBSD firewall-appliance lanes, absorbed from Prominic's standalone
  pfSense-Configurator playbook (generic capability here; org policy data
  stays in consuming playbooks):
  - `firewall/tasks/freebsd.yml` — CGNAT bogon exclusions and CA-bundle
    refresh on pfSense (`firewall_bogon_exclusions`).
  - `ssl/tasks/freebsd.yml` — appliance certificate lifecycle: existing-cert
    deployment from vaulted content vars with webConfigurator refid wiring,
    acme-package provisioning/cleanup, and the refid/acme XML helper tools.
  - New `firewall_notifications` role — SMTP notification configuration.
  - New `firewall_watchdog` role — pfSense Service_Watchdog entries from a
    list variable.
  - `dependencies` role now routes pfSense appliances to their own package
    vars (`vars/pfsense.yml`) — the OPNsense `os-*` plugin set does not exist
    in the pfSense repo.
- Appliance fleet constraint documented throughout: targets run Python 3.7,
  keep the controller on ansible-core 2.16.
