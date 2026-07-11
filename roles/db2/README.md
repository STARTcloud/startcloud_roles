# db2

Ansible role `db2` for the `startcloud.startcloud_roles` collection.

Installs IBM DB2 11.1 on EL systems, optionally creates a database, and optionally
configures HADR primary/standby replication and TSAMP clustering. See
`meta/argument_specs.yml` for the gating variables and `defaults/main.yml` for the
instance identity, installer, and HADR host/port defaults.

TSAMP licensing requires `templates/sam41.lic`, which is operator-supplied and
deliberately not committed to this repository.
