# Ansible Role: Apache 2.x

Installs Apache 2.x on RHEL/CentOS, Debian/Ubuntu, SLES, or Solaris, detects the running
Apache version (2.2 vs 2.4) to render matching directives, and manages listen ports,
enabled/disabled mods, and plain plus SSL virtual hosts.

## Requirements

If you are using SSL/TLS, provide your own certificate and key files. A self-signed
certificate can be generated with a command like
`openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout example.key -out example.crt`.

If you are using Apache with PHP, the `startcloud.startcloud_roles.php` role installs
PHP; use mod_php (add the proper package, e.g. `libapache2-mod-php`, to `php_packages`)
or connect Apache to PHP-FPM.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    apache_enablerepo: ""

The repository to use when installing Apache (RHEL/CentOS only), e.g. EPEL for later
versions than the core repositories carry.

    apache_listen_ip: "*"
    apache_listen_port: 80
    apache_listen_port_ssl: 443

The IP address and ports Apache listens on. Useful when another service (like a reverse
proxy) occupies port 80 or 443.

    apache_create_vhosts: true
    apache_vhosts_filename: "vhosts.conf"
    apache_vhosts_template: "vhosts.conf.j2"

If true, a vhosts file managed by this role's variables is placed in the Apache
configuration folder. If false, place your own vhosts file there instead. The template
path can be overridden for a fully customized VirtualHost layout.

    apache_remove_default_vhost: false

On Debian/Ubuntu, a default virtualhost ships with Apache's configuration. Set `true`
to remove it.

    apache_global_vhost_settings: |
      DirectoryIndex index.php index.html
      # Add other global settings on subsequent lines.

Global Apache settings placed at the top of the role-provided vhosts file.

    apache_vhosts:
      # Additional optional properties: 'serveradmin, serveralias, extra_parameters'.
      - servername: "local.dev"
        documentroot: "/var/www/html"

One entry per virtualhost: `servername` (required), `documentroot` (required),
`allow_override` / `options` (optional, default to the `apache_allow_override` and
`apache_options` values), `serveradmin`, `serveralias`, and `extra_parameters` (any
additional configuration lines). Example redirect to the `www.` site via
`extra_parameters`:

    - servername: "www.local.dev"
      serveralias: "local.dev"
      documentroot: "/var/www/html"
      extra_parameters: |
        RewriteCond %{HTTP_HOST} !^www\. [NC]
        RewriteRule ^(.*)$ http://www.%{HTTP_HOST}%{REQUEST_URI} [R=301,L]

The `|` denotes a multiline scalar block in YAML, so newlines are preserved.

    apache_vhosts_ssl: []

No SSL vhosts are configured by default. Use the same pattern as `apache_vhosts` plus
certificate directives:

    apache_vhosts_ssl:
      - servername: "local.dev"
        documentroot: "/var/www/html"
        certificate_file: "/home/vagrant/example.crt"
        certificate_key_file: "/home/vagrant/example.key"
        certificate_chain_file: "/path/to/certificate_chain.crt"

    apache_ignore_missing_ssl_certificate: true

To only create SSL vhosts whose certificate file already exists (e.g. with Let's
Encrypt), set this to `false` — you may then need multiple playbook runs so certs can be
generated before the vhosts are written.

    apache_ssl_no_log: true

Whether to suppress SSL-related task output (certificate paths) during the run.

    apache_ssl_protocol: "All -SSLv2 -SSLv3"
    apache_ssl_cipher_suite: "AES256+EECDH:AES256+EDH"

SSL protocols and cipher suites for secure connections — sane defaults, adjustable for
compatibility or hardening.

    apache_allow_override: "All"
    apache_options: "-Indexes +FollowSymLinks"

Defaults for the `AllowOverride` and `Options` directives of each vhost's documentroot
directory; individual vhosts can override via `allow_override` / `options`.

    apache_mods_enabled:
      - rewrite
      - ssl
    apache_mods_disabled: []

Apache mods to enable or disable (Debian/Ubuntu symlinks in `mods-enabled`, RHEL drop-in
LoadModule files). See `mods-available` in the Apache config directory for options.

    apache_packages: [platform-specific]

Packages installed per platform — see the files under `vars/` for defaults.

    apache_state: started

Initial Apache daemon state enforced by the role. Generally `started`; use `stopped` if
Apache must stay down while configuration is being repaired.

    apache_enabled: true

Whether the Apache service starts at boot.

    apache_packages_state: present

Set to `latest` (combined with `apache_enablerepo` on RHEL) to upgrade Apache from an
additional repository in place.

## .htaccess-based Basic Authorization

For Basic Auth, use a custom template or `extra_parameters`:

    extra_parameters: |
      <Directory "/var/www/password-protected-directory">
        Require valid-user
        AuthType Basic
        AuthName "Please authenticate"
        AuthUserFile /var/www/password-protected-directory/.htpasswd
      </Directory>

To protect everything within a VirtualHost, use a `Location` block instead of
`Directory`. Generate and upload your own `.htpasswd` file in your playbook.

## Dependencies

None.

## Example Playbook

    - hosts: webservers
      vars:
        apache_listen_port: 8080
        apache_vhosts:
          - servername: "example.com"
            documentroot: "/var/www/vhosts/example_com"
      roles:
        - startcloud.startcloud_roles.apache

## License

GPL-2.0-or-later
