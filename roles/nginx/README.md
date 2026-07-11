# Ansible Role: Nginx

Installs Nginx on RedHat/CentOS, Debian/Ubuntu, ArchLinux, SLES, FreeBSD, or OpenBSD
servers from the appropriate repository for each platform, renders the main
`nginx.conf`, and manages virtual hosts, upstreams, and the service state. You will
likely need extra setup after this role runs, like adding your own vhost `.conf`
describing your particular website.

## Requirements

None.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    nginx_listen_ipv6: true

Whether to listen on IPv6 (applied to all vhosts managed by this role).

    nginx_vhosts: []

A list of vhost definitions (server blocks). Each entry creates a config file named by
`server_name` (or `filename`). If left empty, supply your own virtual host
configuration. See the commented example in `defaults/main.yml` for available options.
A fully-populated entry:

    nginx_vhosts:
      - listen: "443 ssl http2"
        server_name: "example.com"
        server_name_redirect: "www.example.com"
        root: "/var/www/example.com"
        index: "index.php index.html index.htm"
        error_page: ""
        access_log: ""
        error_log: ""
        state: "present"
        template: "{{ nginx_vhost_template }}"
        filename: "example.com.conf"
        extra_parameters: |
          location ~ \.php$ {
              fastcgi_split_path_info ^(.+\.php)(/.+)$;
              fastcgi_pass unix:/var/run/php-fpm.sock;
              fastcgi_index index.php;
              fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
              include fastcgi_params;
          }
          ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;
          ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;
          ssl_protocols       TLSv1.1 TLSv1.2;
          ssl_ciphers         HIGH:!aNULL:!MD5;

Mind the indentation: the first `extra_parameters` line is a normal 2-space indent, the
rest indent relative to it; the whole block lands 4-space indented in the generated
file. A secondary redirect vhost:

    - listen: "80"
      server_name: "example.com www.example.com"
      return: "301 https://example.com$request_uri"
      filename: "example.com.80.conf"

Note: `filename` defaults to the first domain in `server_name` — two vhosts with the
same domain (e.g. a redirect) need explicit filenames so one doesn't override the other.

    nginx_remove_default_vhost: false

Whether to remove the 'default' virtualhost configuration supplied by Nginx. Useful if
you want the base `/` URL directed at one of your own vhosts.

    nginx_upstreams: []

For load balancing, define one or more upstream sets here, then point a server block at
them (e.g. `proxy_pass http://myapp1;`). See the commented example in
`defaults/main.yml`.

    nginx_user: [OS-specific]

The user under which Nginx runs — `nginx` on RedHat/SUSE, `www-data` on Debian, `http`
on Arch, `www` on FreeBSD/OpenBSD.

    nginx_worker_processes: "{{ ansible_processor_vcpus | default(ansible_processor_count) }}"
    nginx_worker_connections: "1024"
    nginx_multi_accept: "off"

Workers should match your core count; connections is per worker (each keepalive client
holds one for its timeout). Set `nginx_multi_accept: "on"` to accept all new connections
at once.

    nginx_error_log: "/var/log/nginx/error.log warn"
    nginx_access_log: "/var/log/nginx/access.log main buffer=16k flush=2m"

Default error and access logs. Set to `off` to disable a log entirely.

    nginx_sendfile: "on"
    nginx_tcp_nopush: "on"
    nginx_tcp_nodelay: "on"

TCP connection options.

    nginx_keepalive_timeout: "75"
    nginx_keepalive_requests: "600"

Keepalive settings. Use a higher timeout for polling-style traffic, lower for sites
where visitors load a few pages and leave.

    nginx_server_tokens: "on"

Whether nginx reports its version in HTTP headers. Set `"off"` to hide it.

    nginx_client_max_body_size: "64m"

Largest possible upload, since uploads pass through Nginx before reaching a backend
like php-fpm. `client intended to send too large body` errors mean this is too low.

    nginx_server_names_hash_bucket_size: "64"

Increase if you have many (or very long) server names.

    nginx_proxy_cache_path: ""

Set as the `proxy_cache_path` directive (e.g. `"/var/cache/nginx keys_zone=cache:32m"`)
to use Nginx's cache as a reverse proxy; empty leaves it unconfigured.

    nginx_extra_http_options: ""

Literal extra lines for the top-level `http` block, e.g.:

    nginx_extra_http_options: |
      proxy_buffering    off;
      proxy_set_header   X-Real-IP $remote_addr;
      proxy_set_header   X-Scheme $scheme;
      proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header   Host $http_host;

    nginx_extra_conf_options: ""

Literal extra lines for the top of `nginx.conf`, e.g.:

    nginx_extra_conf_options: |
      worker_rlimit_nofile 8192;

    nginx_log_format: |-
      '$remote_addr - $remote_user [$time_local] "$request" '
      '$status $body_bytes_sent "$http_referer" '
      '"$http_user_agent" "$http_x_forwarded_for"'

Configures Nginx's `log_format`.

    nginx_default_release: ""

(Debian/Ubuntu only) Repository target passed as apt's `-t` option, e.g. a backports
release carrying a newer Nginx.

    nginx_ppa_use: false
    nginx_ppa_version: stable

(Ubuntu only) Use the official Nginx PPA (`stable` or `development`) instead of the
system package. Enabling this removes the distro nginx package first so the PPA version
installs cleanly.

    nginx_yum_repo_enabled: true

(RedHat/CentOS only) Set `false` to skip installing the nginx yum repository (e.g. to
use OS stable packages or Satellite).

    nginx_zypper_repo_enabled: true

(SUSE only) Set `false` to skip installing the nginx zypper repository.

    nginx_service_state: started
    nginx_service_enabled: true

Service state and boot enablement — override when installing in a container or when you
need finer control.

    nginx_port_forwards: [...]

Port-forward definitions consumed by the STARTcloud provisioner for the Nginx service
(guest/host ports, bind IP, proxied flag).

## Overriding configuration templates

If a needed option isn't exposed via variables, override the templates:

    nginx_conf_template: "nginx.conf.j2"
    nginx_vhost_template: "vhost.j2"

Templates can also be set per vhost:

    nginx_vhosts:
      - listen: "80 default_server"
        server_name: "site1.example.com"
        root: "/var/www/site1.example.com"
        index: "index.php index.html index.htm"
        template: "{{ playbook_dir }}/templates/site1.example.com.vhost.j2"

You can copy and modify the provided templates, or extend them with Jinja2 template
inheritance and override only the block you need. Example — enabling gzip:

    nginx_conf_template: "{{ playbook_dir }}/templates/nginx.conf.j2"

Then in that child template:

    {% extends 'roles/startcloud.startcloud_roles.nginx/templates/nginx.conf.j2' %}

    {% block http_gzip %}
        gzip on;
        gzip_proxied any;
        gzip_static on;
        gzip_vary on;
        gzip_comp_level 6;
        gzip_buffers 16 8k;
        gzip_min_length 512;
    {% endblock %}

## Dependencies

None.

## Example Playbook

    - hosts: server
      roles:
        - { role: startcloud.startcloud_roles.nginx }

## License

GPL-2.0-or-later
