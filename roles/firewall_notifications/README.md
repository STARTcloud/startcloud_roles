# firewall_notifications

Ansible role `firewall_notifications` for the `startcloud.startcloud_roles` collection.

Configures SMTP email notifications on firewall appliances by writing the
`<smtp>` block into pfSense's `config.xml` and reloading the configuration.
OPNsense support slots into the same role when its config surgery is
implemented.

Fleet constraint: appliances run Python 3.7 — keep the controller on
ansible-core 2.16. Credentials are supplied via vault
(`vault_firewall_notifications_pass`); the tracked defaults are dummies.
