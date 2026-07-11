# Ansible Role: Certbot (for Let's Encrypt)

Installs and configures Certbot (for Let's Encrypt). Certbot can be installed from OS
packages, from Snap, or from Git source; the role can optionally generate certificates
(standalone or webroot method) and configures a daily auto-renewal cron job.

## Requirements

If installing from source, Git is required on the host.

## Role Variables

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    certbot_install_method: package

Controls how Certbot is installed. Available options are `package`, `snap`, and `source`.

    certbot_auto_renew: true
    certbot_auto_renew_user: "{{ ansible_user | default(lookup('env', 'USER')) }}"
    certbot_auto_renew_hour: "3"
    certbot_auto_renew_minute: "30"
    certbot_auto_renew_options: "--quiet"

By default, this role configures a cron job to run `certbot renew` under the provided
user account at the given hour and minute, every day. Prefer a custom user/hour/minute
so the renewal runs during a low-traffic period under a non-root account.

### Automatic Certificate Generation

The `standalone` and `webroot` methods are supported for generating new certificates.

    certbot_create_if_missing: false

Set to `true` to let this role generate certs.

    certbot_create_method: standalone

Method used for generating certs — allowed values: `standalone` or `webroot`.

    certbot_testmode: false

Use Let's Encrypt's staging environment (`--test-cert`) instead of issuing real
certificates.

    certbot_hsts: false

Enable HTTP Strict Transport Security for the certificate generation.

    certbot_admin_email: "{{ email | default('support@startcloud.com') }}"

The email address used to agree to Let's Encrypt's TOS and subscribe to cert-related
notifications. Set this to an address your organization monitors.

    certbot_certs: []
      # - email: janedoe@example.com
      #   webroot: "/var/www/html"
      #   domains:
      #     - example1.com
      #     - example2.com
      # - domains:
      #     - example3.com

A list of domains (and other data) for which certs should be generated. An `email` key
on any item overrides `certbot_admin_email`. With the `webroot` method, a `webroot` item
must be provided, and your webserver must serve challenge files from that directory.

    certbot_webroot: /var/www/letsencrypt

Default webroot used when a cert item doesn't define its own.

    certbot_create_extra_args: ""

Extra arguments appended to the certbot create command. The fully assembled command
lives in `certbot_create_command` (see `defaults/main.yml`) and can be overridden
entirely if needed.

#### Standalone Certificate Generation

    certbot_create_standalone_stop_services:
      - nginx

Services stopped while certbot runs its own standalone server on ports 80 and 443,
via generated pre/post renewal hooks. If you're running Apache, set this to `apache2`
(Debian/Ubuntu) or `httpd` (RHEL); add anything else bound to ports 80/443. The services
are only stopped the first time a new cert is generated, and again around renewals via
the same hooks.

#### Webroot Certificate Generation

When using the `webroot` creation method, every `certbot_certs` item needs a `webroot`
directory that your webserver serves.

### Snap Installation

Setting `certbot_install_method: snap` installs Certbot via Snap (snapd is installed and
`snap core` refreshed first). This is the install method the Certbot maintainers
recommend for most distributions.

### Source Installation from Git

    certbot_repo: https://github.com/certbot/certbot.git
    certbot_version: master
    certbot_keep_updated: true

Certbot Git repository options for `certbot_install_method: source`. If
`certbot_keep_updated` is true, the repository is updated every time this role runs.

    certbot_dir: /opt/certbot

The directory Certbot is cloned into.

## Dependencies

None.

## Example Playbook

    - hosts: servers

      vars:
        certbot_auto_renew_user: your_username_here
        certbot_auto_renew_minute: "20"
        certbot_auto_renew_hour: "5"

      roles:
        - startcloud.startcloud_roles.certbot

### Certbot certificate auto-renewal

You can test the auto-renewal (without actually renewing) with:

    certbot renew --dry-run

See full documentation and options on the [Certbot website](https://certbot.eff.org/).

## License

GPL-2.0-or-later
