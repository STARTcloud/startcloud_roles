# Playbooks

`site.yml` applies the roles of this collection to the groups of one inventory. Every play carries the tag of its job, so one tag runs one job, several tags run several, and no tag runs the whole file in order. Runs use this checkout, cloned as `<folder>/ansible_collections/startcloud/startcloud_roles` and run from its `playbooks/` directory, whose `ansible.cfg` names that folder as the collections path, so a role change is live in the next run; the collections the roles call come from the Debian `ansible` package.

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
| `controllers` | the node that mails the maintenance window and renews the certificates, reached like every other host |
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
| `hosts-file` | `vms`, `hypervisors`, `pis` | Writes the site hosts file |
| `ntp` | `vms`, `pis`, `hypervisors`, `outside`, `firewalls`, then `openwrt`, `switches` | Points every clock at its time servers |
| `monitoring` | `collectors`, then `vms`, `pis`, `hypervisors`, `outside`, `firewalls`, then `openwrt`, `switches` | Issues the collector's certificate, forwards logs to the collector, answers SNMP, records every program start and login and hands the records to syslog |
| `motd` | `vms`, `pis`, `hypervisors` | Brands the login message with the profile named by `vendor` and installs the `sysinfo` command |
| `pam-ciba` | `pam_ciba` | Gates SSH logins on push approval |
| `system-proxy` | `system_proxy` | Writes the system-wide and package-manager proxy settings |
| `proxies` | `proxies` | Installs HAProxy with the site's template named by `haproxy_cfg`, keepalived with the site's VRRP values, and squid where `squid_proxy` is set |
| `update` | `vms`, `pis`, then `windows`, then `hypervisors`, then `controllers`, then `openwrt` | Upgrades packages one node at a time, updates compose containers where `container_compose_update` is set, reboots where allowed, waits for a rebooted host's boot-time guests to run again, reports what still waits, fails on any node it never reached, then upgrades the access points |
| `maintenance` | the `update` groups and `controllers` | The maintenance window: a mail that it opens, the `update` plays with reboots allowed, the certificate renewal on the controller, a mail that it is done with the log attached, and the controller's own reboot last; a failing node mails the log and stops the run |
| `certificates` | `controllers`, then `certificates` | Issues or adopts the controller's certificates by DNS-01, then pushes them to every target |
| `opnsense` | `firewalls` | Applies the pending OPNsense updates through the firmware API, installs the baseline packages and the repositories in `opnsense_repos`, issues the web GUI certificate through the ACME client, reboots where allowed, places root's key and the web GUI sign-in through the OpenID Provider |
| `openwrt` | `openwrt` | Upgrades the access points' firmware and packages |

The access points and the switches run no Python, so their plays gather no facts: each group sets `ansible_os_family` (`openwrt`, `ios`) and the fact names the roles dispatch on in the inventory, and the roles' `openwrt` and `ios` lanes read nothing from the device but what they set. The switches connect over `network_cli` with `ansible_network_os: cisco.ios.ios`.

## Updates

A node reboots only when the run allows it and the node does not carry `reboot_never`:

```sh
ansible-playbook -i inventory/home.yml site.yml --tags update --diff -e reboots_allowed=true
```

A node that carries `galera_node: true` is upgraded only while it reads `Synced` in a `Primary` cluster, and the run waits for it to read so again after its upgrade and after its reboot before the next node starts.

A node that carries `dependencies_install_packages: false` is upgraded and never given a package it does not have; one that carries `dependencies_upgrade: false` only reports what is upgradable. A node that carries `update_extra_repos` passes that list to the role as its whole repository list, in place of the one the role's vars file holds.

A Proxmox host that rebooted is not done until every guest it starts on boot reports running again. The last play of an update run lists the nodes still waiting for a reboot or an update, and fails the run, with the window's mail, on any node it never reached.

An OPNsense firewall applies every pending update as one job and reboots only when the run allows it:

```sh
ansible-playbook -i inventory/home.yml site.yml --tags opnsense --diff -e reboots_allowed=true
```

An access point upgrades only when `owut check` reports it safe; the run waits for it to come back and checks that `owut check` then reports nothing more.

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

The first domain names the lineage, or `name` does where the first domain is a wildcard. An acme-dns provider reads `secrets.acmedns_api_url` and `secrets.acmedns_credentials`, the registrations keyed by domain; a Cloudflare provider reads `secrets.cloudflare_api_token`; an rfc2136 provider reads `secrets.rfc2136_server`, `secrets.rfc2136_name` and `secrets.rfc2136_secret`, with `secrets.rfc2136_port` and `secrets.rfc2136_algorithm` where the defaults do not fit. Renewal is automatic: certbot's timer on Debian, the ACME client on OPNsense; a renewal runs the scripts in `ssl_renewal_hooks`, and a controller lists the push as one of them:

```yaml
ssl_renewal_hooks:
  - { name: certificates, command: "cd {{ playbook_dir }} && ansible-playbook -i {{ inventory_file }} site.yml --tags certificates" }
```

Each host of the `certificates` group names the lineage it receives in `ssl_push_lineage`. With `ssl_push` the role writes the chain, the CA chain, the key and the combined pem into the host's `cert_dir`, owned by `ssl_push_owner`, then runs the host's `ssl_renewal_hooks` when a file changed or the host does not serve the lineage on `ssl_push_verify_port`, and compares the served certificate to the lineage afterwards; what a hook does is the host's business, a service reload, an appliance's own certificate command, a database's `FLUSH SSL`:

```yaml
ssl_push: true
ssl_push_verify_port: 443
ssl_renewal_hooks:
  - { name: haproxy, command: systemctl reload haproxy }
```

A port that negotiates TLS inside its protocol names it in `ssl_push_verify_starttls`, such as `mysql`. CA files a service on the host verifies peers against go in `ssl_push_ca_files`, paths on the controller, and land under `cert_dir/ca` by their own names. A host that takes the push over an API carries `ansible_connection: local` and `ssl_push_netscaler` or `ssl_push_fortigate` instead.

## Logs and SNMP

`syslog_server`, `syslog_protocol` and `syslog_port` set where a node sends its logs; the protocol is `udp`, `tcp` or `tls`. The collector's receivers are set with `syslog_receive_udp`, `syslog_receive_tcp` and `syslog_receive_tls`.

The `audit` role records every program a logged-in account starts, with its arguments, and every login, logout and authentication, and hands each record to syslog, so it rides the same forwarding. On Linux the rules lock the audit setup until reboot, so a rules change made later is refused until the node reboots; the role reports when one waits. `audit_syslog_facility` names the facility the records carry, `audit_rules_extra` adds rule lines of the site's own.

## Push-approved SSH

The `pam-ciba` tag reads `lockdown_pam_ciba_issuer`, each host's `lockdown_pam_ciba_client_id`, and `lockdown_pam_ciba_users`, which maps a local account to its provider account. Accounts in `lockdown_pam_ciba_key_users` sign in by key alone; the account named by `lockdown_pam_ciba_health_user` keeps its password login. From the addresses in `lockdown_pam_ciba_key_addresses` the mapped accounts sign in by key alone and pam-ciba approves with no push; the accounts in `lockdown_pam_ciba_sudo_users` have a sudo that asks PAM, so their sudo passes from those addresses and is refused from anywhere else. On OmniOS the module is a `binding` entry of the `sshd` service in `/etc/pam.conf`, so an account with no entry in `lockdown_pam_ciba_users` falls through to its password.
