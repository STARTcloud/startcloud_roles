# firewall_watchdog

Ansible role `firewall_watchdog` for the `startcloud.startcloud_roles` collection.

Writes Service_Watchdog entries into a pfSense appliance's `config.xml` and
reloads the configuration. The watched services are supplied by the consuming
playbook via `firewall_watchdog_services` — the role ships none of its own.

Firewall appliances only (hence the name): requires
`pfSense-pkg-Service_Watchdog` on the appliance (install through the
`dependencies` role's package list). On Linux hosts the `monit` role covers
the same concept; OPNsense's equivalent (Monit plugin) slots into this role
when implemented.

Fleet constraint: appliances run Python 3.7 — keep the controller on
ansible-core 2.16.
