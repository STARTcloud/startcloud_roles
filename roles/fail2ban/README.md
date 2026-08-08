# fail2ban

Ansible role `fail2ban` for the `startcloud.startcloud_roles` collection.

Installs Fail2ban, renders the server settings into `/etc/fail2ban/fail2ban.local`
and the jail overrides into `/etc/fail2ban/jail.local`, and starts and enables the
service. Both files are `.local` overrides, read after the packaged configuration
and surviving package upgrades; changes restart the service through a handler.

The role hardcodes no protected service. Consumers (playbooks or service roles)
ship their own filters and jails through `fail2ban_filters` and `fail2ban_jails`,
keeping service knowledge in the composition layer.

## Variables

| Variable | Default | Description |
| --- | --- | --- |
| `run_tasks` | `true` | Master gate — when false the role loads its vars but runs no tasks. |
| `fail2ban_loglevel` | `INFO` | Server log verbosity, rendered into `fail2ban.local`. |
| `fail2ban_logtarget` | `/var/log/fail2ban.log` | Server log path. |
| `fail2ban_socket` | `/var/run/fail2ban/fail2ban.sock` | Server socket path. |
| `fail2ban_pidfile` | `/var/run/fail2ban/fail2ban.pid` | Server PID file. |
| `fail2ban_dbfile` | `/var/lib/fail2ban/fail2ban.sqlite3` | Ban-state database. |
| `fail2ban_dbpurgeage` | `1d` | Age after which old bans purge from the database. |
| `fail2ban_default_bantime` | `""` | Optional `[DEFAULT]` bantime in `jail.local`; omitted when empty. |
| `fail2ban_default_findtime` | `""` | Optional `[DEFAULT]` findtime; omitted when empty. |
| `fail2ban_default_maxretry` | `""` | Optional `[DEFAULT]` maxretry; omitted when empty. |
| `fail2ban_ignoreip` | `""` | Extra space-separated ignoreip entries appended after the loopback addresses; line omitted when empty. |
| `fail2ban_sshd_enabled` | `false` | Whether the packaged Debian `[sshd]` jail stays enabled. |
| `fail2ban_filters` | `[]` | Consumer-supplied filters; each `{ name, content }` writes `/etc/fail2ban/filter.d/<name>.conf`. |
| `fail2ban_jails` | `[]` | Consumer-supplied jail blocks appended to `jail.local`; each item requires `name` and may set `enabled`, `port`, `logpath`, `backend`, `filter`, `action`, `maxretry`, `bantime`, `findtime`. |

## Example: consumer-supplied service jails

```yaml
- role: startcloud.startcloud_roles.fail2ban
  vars:
    fail2ban_filters:
      - name: asterisk-security
        content: |
          [Definition]
          failregex = ^.*SecurityEvent="InvalidAccountID".*RemoteAddress="IPV[46]/(UDP|TCP|TLS|WS|WSS)/<HOST>/\d+".*$
          ignoreregex =
    fail2ban_jails:
      - name: asterisk-security
        enabled: true
        port: "5060,5061"
        logpath: /var/log/asterisk/security
        maxretry: 3
        bantime: "48h"
        filter: asterisk-security
        action: "iptables-allports[name=asterisk-security, protocol=all]"
```
