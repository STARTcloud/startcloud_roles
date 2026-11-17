# Playbooks

Each playbook applies roles of this collection to the groups of one inventory. Runs use the installed collection, so the collection is rebuilt and installed after any role change.

## Before a run

From the repository root:

```sh
ansible-lint --profile production
ansible-galaxy collection build --force
ansible-galaxy collection install ./startcloud-startcloud_roles-*.tar.gz --force
```

From `playbooks/`, a check run shows what a real run changes:

```sh
ansible-playbook -i inventory/home.yml ntp.yml --check --diff
ansible-playbook -i inventory/home.yml ntp.yml --diff
```

`--limit` narrows a run to one host or group:

```sh
ansible-playbook -i inventory/home.yml ntp.yml --diff --limit pis
```

## Inventory

The inventory lives under `inventory/` and stays out of the repository. It holds the hosts, their addresses, and every value the roles read, secrets included.

| Group | Members |
| --- | --- |
| `vms` | virtual machines |
| `pis` | Raspberry Pis |
| `hypervisors` | hypervisor hosts |
| `outside` | hosts off the home network |
| `openwrt` | OpenWrt access points |
| `firewalls` | OPNsense firewalls |
| `switches` | network switches |
| `collectors` | the log collector |
| `pam_ciba` | hosts whose SSH logins need push approval |

## Playbooks

| Playbook | Groups | Does |
| --- | --- | --- |
| `update-vms.yml` | `vms`, `pis` | Upgrades packages one host at a time, updates compose containers where `container_compose_update` is set, reports pending reboots |
| `update-hosts.yml` | `hypervisors` | Upgrades packages one host at a time, reports pending reboots |
| `opnsense.yml` | `firewalls` | Applies pending OPNsense package updates, installs the baseline packages and the STARTcloud package repository, issues and renews the web GUI certificate |
| `openwrt.yml` | `openwrt` | Points the clock at the gateway, points logs at the collector, upgrades firmware and packages |
| `ntp.yml` | `vms`, `pis`, `hypervisors`, `outside` | Points every clock at its time servers |
| `hosts-file.yml` | `vms`, `hypervisors` | Writes the site hosts file |
| `authorized-key.yml` | `vms`, `hypervisors`, `pis` | Places the controller's public key on the login account |
| `pam-ciba.yml` | `pam_ciba` | Gates SSH logins on push approval |
| `monitoring.yml` | `collectors`, then `vms`, `pis`, `hypervisors`, `outside` | Issues the collector's certificate, forwards logs to the collector, answers SNMP |

## Updates

A node reboots only when the run allows it and the node does not carry `reboot_never`:

```sh
ansible-playbook -i inventory/home.yml update-vms.yml --diff -e reboots_allowed=true
```

The last play of each update run lists the nodes still waiting for a reboot or an update.

OPNsense base and kernel updates stay off unless asked for:

```sh
ansible-playbook -i inventory/home.yml opnsense.yml --diff -e opnsense_update_base_kernel=true -e reboots_allowed=true
```

An access point upgrades only when `owut check` reports it safe, and the run waits for it to come back on the new release.

## Certificates

`monitoring.yml` and `opnsense.yml` issue certificates by DNS-01. A host gets one when its inventory entry names the certificate and the provider:

```yaml
ssl_dns01_certs:
  - { domains: [host.example.org], provider: cloudflare }
```

The provider token comes from `secrets.cloudflare_api_token` in the inventory. Renewal is automatic: certbot's timer on Debian, the ACME client on OPNsense.

## Logs and SNMP

`syslog_server`, `syslog_protocol` and `syslog_port` set where a node sends its logs; the protocol is `udp`, `tcp` or `tls`. The collector's receivers are set with `syslog_receive_udp`, `syslog_receive_tcp` and `syslog_receive_tls`.

## Push-approved SSH

`pam-ciba.yml` reads `lockdown_pam_ciba_issuer`, each host's `lockdown_pam_ciba_client_id`, and `lockdown_pam_ciba_users`, which maps a local account to its provider account. Accounts in `lockdown_pam_ciba_key_users` sign in by key alone.
