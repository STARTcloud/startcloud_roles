# ipsec

Ansible role `ipsec` for the `startcloud.startcloud_roles` collection.

Sets up site-to-site IPsec tunnels with strongSwan (charon-systemd + swanctl):
one routed xfrm interface per peer, managed through ifupdown, with optional
network-namespace isolation for the whole stack. Derived from Philipp
Riederer's `setup_ipsec` role (BSD-3-Clause) and rewritten to STARTcloud
conventions.

Currently Debian-family only — other OS families fail fast with a clear
message. Extend by adding a `tasks/setup-<OSFamily>.yml`.

## How it works

- Renders `/etc/swanctl/conf.d/ansible-managed.conf` (mode `0600`, task runs
  `no_log` because the file carries PSKs) with one IKEv2 PSK connection per
  entry in `ipsec_peers`.
- Disables charon's automatic route installation and the legacy
  `strongswan-starter` service.
- Creates `ipsec0`, `ipsec1`, … xfrm interfaces in `/etc/network/interfaces`;
  peer N uses `if_id = ipsec_base_if_id + N` on both the interface and the
  swanctl connection, so the base id must match on both tunnel ends.
- Routes each peer's `routes` list via the peer tunnel address derived from
  `ipsec_net` with `ansible.utils.ipaddr('peer')`.

## Example

```yaml
roles:
  - name: startcloud.startcloud_roles.ipsec
vars:
  ipsec_peers:
    - name: sitea
      me: 198.51.100.10
      other: 203.0.113.20
      psk: "{{ vault_ipsec_psk_sitea | default('CHANGEME') }}"
      ipsec_net: 10.10.0.1/30
      routes:
        - 192.168.50.0/24
```

## Secrets

PSKs never live in the repo. Put real values in the gitignored root
`vault.yml` (same pattern as the rest of the collection):

```yaml
vault_ipsec_psk_sitea: "the-real-psk"
```

and load it at runtime (`-e @vault.yml`, or encrypt it with
`ansible-vault`). Tracked files only ever carry the `CHANGEME` dummy.

All variables are documented in [meta/argument_specs.yml](meta/argument_specs.yml).
