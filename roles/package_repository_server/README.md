# package_repository_server

Ansible role `package_repository_server` for the `startcloud.startcloud_roles` collection.

Builds and serves OS package repositories — OmniOS IPS pkg server instances
(base/core/extra/public/private) and a PGP-signed Debian APT repository.

NOTE: `tasks/main.yml` is currently a stub (commented out); the OS-specific task
files are invoked directly by dedicated plays. This role is quarantined for a
dedicated rework session.
