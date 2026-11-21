# Playbooks

`site.yml` applies the roles of this collection to the groups of one inventory. Every play carries the tag of its job, so one tag runs one job, several tags run several, and no tag runs the whole file in order. Runs use this checkout, found on a collections path as `ansible_collections/startcloud/startcloud_roles`, so a role change is live in the next run; the collections the roles call come from the Debian `ansible` package.

## Before a run

From the repository root:

```sh
ansible-lint --profile production
```

From `playbooks/`, a check run shows what a real run changes:

```sh
ansible-playbook -i inventory/home.yml site.yml --tags ntp --check --diff
ansible-playbook -i inventory/home.yml site.yml --tags ntp --diff
```

`--limit` narrows a run to one host or group:

```sh
ansible-playbook -i inventory/home.yml site.yml --tags ntp --diff --limit pis
```

Every run appends to `~/ansible.log` of the account that runs it.

## Inventory

The inventory lives under `inventory/` and stays out of the repository. It holds the hosts, their addresses, and every value the roles read, secrets included.

| Group | Members |
| --- | --- |
| `controllers` | the node the playbook runs from, with `ansible_connection: local` |
| `vms` | virtual machines |
| `pis` | Raspberry Pis |
| `hypervisors` | hypervisor hosts |
| `windows` | Windows nodes, reached over WinRM |
| `outside` | hosts off the site's network |
| `openwrt` | OpenWrt access points |
| `firewalls` | OPNsense firewalls |
| `switches` | network switches |
| `collectors` | the log collector |
| `pam_ciba` | hosts whose SSH logins need push approval |
| `system_proxy` | hosts whose processes reach out through a proxy |
| `proxies` | the HAProxy and keepalived pair in front of a site, with squid where `squid_proxy` is set |
| `certificates` | every host that receives a certificate from the controller |

A group the site does not have is declared with no hosts, so every play finds its pattern.

## Tags

| Tag | Groups | Does |
| --- | --- | --- |
| `authorized-key` | `vms`, `hypervisors`, `pis` | Places the controller's public key on the login account |
| `hosts-file` | `vms`, `hypervisors` | Writes the site hosts file |
| `ntp` | `vms`, `pis`, `hypervisors`, `outside` | Points every clock at its time servers |
| `monitoring` | `collectors`, then `vms`, `pis`, `hypervisors`, `outside` | Issues the collector's certificate, forwards logs to the collector, answers SNMP |
| `pam-ciba` | `pam_ciba` | Gates SSH logins on push approval |
| `system-proxy` | `system_proxy` | Writes the system-wide and package-manager proxy settings |
| `proxies` | `proxies` | Installs HAProxy with the site's template named by `haproxy_cfg`, keepalived with the site's VRRP values, and squid where `squid_proxy` is set |
| `update` | `vms`, `pis`, `hypervisors`, `windows`, `controllers` | Upgrades packages one node at a time, updates compose containers where `container_compose_update` is set, reboots where allowed, reports what still waits |
| `maintenance` | the `update` groups and `controllers` | The maintenance window: a mail that it opens, the `update` plays with reboots allowed, the certificate renewal on the controller, a mail that it is done with the log attached, and the controller's own reboot last; a failing node mails the log and stops the run |
| `certificates` | `controllers`, then `certificates` | Issues or adopts the controller's certificates by DNS-01, then pushes them to every target |
| `opnsense` | `firewalls` | Applies pending OPNsense package updates, installs the baseline packages and the repositories in `opnsense_repos`, issues and renews the web GUI certificate |
| `openwrt` | `openwrt` | Points the clock at the gateway, points logs at the collector, upgrades firmware and packages |

## Updates

A node reboots only when the run allows it and the node does not carry `reboot_never`:

```sh
ansible-playbook -i inventory/home.yml site.yml --tags update --diff -e reboots_allowed=true
```

A node that carries `galera_node: true` is upgraded only while it reads `Synced` in a `Primary` cluster, and the run waits for it to read so again after its upgrade and after its reboot before the next node starts.

A node that carries `dependencies_install_packages: false` is upgraded and never given a package it does not have; one that carries `dependencies_upgrade: false` only reports what is upgradable. A node that carries `update_extra_repos` passes that list to the role as its whole repository list, in place of the one the role's vars file holds.

The last play of an update run lists the nodes still waiting for a reboot or an update.

OPNsense base and kernel updates stay off unless asked for:

```sh
ansible-playbook -i inventory/home.yml site.yml --tags opnsense --diff -e opnsense_update_base_kernel=true -e reboots_allowed=true
```

An access point upgrades only when `owut check` reports it safe, and the run waits for it to come back on the new release.

## The maintenance window

```sh
ansible-playbook -i inventory/home.yml site.yml --tags maintenance -e reboots_allowed=true
```

The mails go through the relay named in the inventory by `maintenance_mail_host`, `maintenance_mail_port`, `maintenance_mail_username`, `maintenance_mail_password`, `maintenance_mail_from` and `maintenance_mail_to`; `maintenance_name` is the name in their subject. `reboots_allowed` is what lets a node reboot, so the window carries it on its command line and a run without it reboots nothing. The controller is never rebooted inside the run: it is upgraded after every other node, and when it asks for a reboot the closing play schedules one a minute after the mail.

## Certificates

The controller issues certificates by DNS-01. Its inventory entry names each certificate and its provider:

```yaml
ssl_dns01_certs:
  - { domains: [host.example.org], provider: cloudflare }
  - { domains: [portal.example.org, tunnel.example.org], provider: rfc2136 }
```

The first domain names the lineage. A Cloudflare provider reads `secrets.cloudflare_api_token`; an rfc2136 provider reads `secrets.rfc2136_server`, `secrets.rfc2136_name` and `secrets.rfc2136_secret`, with `secrets.rfc2136_port` and `secrets.rfc2136_algorithm` where the defaults do not fit. Renewal is automatic: certbot's timer on Debian, the ACME client on OPNsense; a renewal runs the scripts in `ssl_renewal_hooks`, and a controller lists the push as one of them:

```yaml
ssl_renewal_hooks:
  - { name: certificates, command: "cd /home/startcloud/startcloud_roles/playbooks && ansible-playbook -i inventory/s2.yml site.yml --tags certificates" }
```

Each host of the `certificates` group names the lineage it receives in `ssl_push_lineage` and the push it takes: `ssl_push_files` writes the chain, key and combined pem into the host's `cert_dir` and runs its own `ssl_renewal_hooks`; `ssl_push_uds`, `ssl_push_galera`, `ssl_push_vdi_health`, `ssl_push_netscaler` and `ssl_push_fortigate` install it the way that service takes a certificate. A host that takes the push over an API, such as a NetScaler, carries `ansible_connection: local`.

## Logs and SNMP

`syslog_server`, `syslog_protocol` and `syslog_port` set where a node sends its logs; the protocol is `udp`, `tcp` or `tls`. The collector's receivers are set with `syslog_receive_udp`, `syslog_receive_tcp` and `syslog_receive_tls`.

## Push-approved SSH

The `pam-ciba` tag reads `lockdown_pam_ciba_issuer`, each host's `lockdown_pam_ciba_client_id`, and `lockdown_pam_ciba_users`, which maps a local account to its provider account. Accounts in `lockdown_pam_ciba_key_users` sign in by key alone.
