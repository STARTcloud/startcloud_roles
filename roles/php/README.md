# Ansible Role: PHP

Installs PHP on Debian/Ubuntu and RHEL-family servers — from OS packages by default or
compiled from source — and manages a rendered `php.ini`, OpCache and APCu extension
configuration, and PHP-FPM pools.

## Requirements

If you're using an older LTS release with an outdated PHP, you need a repo or PPA with a
maintained PHP version — this role works with
[PHP versions currently supported](https://www.php.net/supported-versions.php) by the
PHP community. Pair it with `startcloud.startcloud_roles.php_versions` to select the
version.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    php_packages: []

A list of the PHP packages to install (OS-specific by default — see `vars/`). You'll
likely want common packages like `php`, `php-cli`, `php-devel` and `php-pdo`, plus
whatever else you need (e.g. `php-gd` for image manipulation, `php-ldap` for LDAP
authentication).

_Note: on Debian/Ubuntu you also need `libapache2-mod-fastcgi` (for cgi/PHP-FPM) or
`libapache2-mod-php8.2` (or similar, per PHP version) to use `mod_php` with Apache._

    php_packages_extra: []

Extra PHP packages to install without overriding the default list.

    php_enable_webserver: true

If PHP is tied to a web server (Apache, Nginx, ...), keep the default. Set `false` for
CLI-only usage so the role doesn't attempt to interact with a web server.

    php_webserver_daemon: "httpd"

`httpd` on RedHat/CentOS, `apache2` on Debian/Ubuntu by default. Change to your
webserver's daemon name (e.g. `nginx`) if different — the "Restart webserver" handler
targets it.

    php_enablerepo: ""

(RHEL-family only) Comma-separated additional repositories to enable when installing
(e.g. `remi-php82,epel`).

    php_default_version_debian: ""

(Debian/Ubuntu only) The default PHP version in the OS repositories, set per
distro/version in `vars/` and overridable here (e.g. `"8.2"`). To switch versions
easily, use the `startcloud.startcloud_roles.php_versions` role.

    php_packages_state: "present"

Set to `"latest"` (combined with `php_enablerepo` on RHEL) to upgrade or switch PHP
versions from a different repository without manual uninstalls.

    php_install_recommends: false

(Debian/Ubuntu only) Whether apt installs recommended packages — kept off so PPAs like
Sury's don't drag in unwanted extra PHP versions.

    php_executable: "php"

The executable used when calling PHP from the command line.

### PHP-FPM

PHP-FPM is the normal way of running PHP-based sites behind Nginx (and works with other
webservers too). To manage FPM with this role:

    php_enable_php_fpm: false

Set `true` to render pools and manage the FPM service.

    php_fpm_state: started
    php_fpm_enabled_on_boot: true

FPM daemon state; use `stopped`/`false` to install and configure without running (e.g.
containers).

    php_fpm_handler_state: restarted

The handler restarts PHP-FPM by default; `reloaded` reloads instead.

    php_fpm_pools:
      - pool_name: www
        pool_template: www.conf.j2
        pool_listen: "127.0.0.1:9000"
        pool_listen_allowed_clients: "127.0.0.1"
        pool_pm: dynamic
        pool_pm_max_children: 50
        pool_pm_start_servers: 5
        pool_pm_min_spare_servers: 5
        pool_pm_max_spare_servers: 5
        pool_pm_max_requests: 0
        pool_pm_status_path: ""

List of PHP-FPM pools to create (the `www` pool by default). For settings beyond these,
point `pool_template` at your own template.

### php.ini settings

    php_use_managed_ini: true

By default the role renders its own `php.ini` from the variables below. Set `false` to
self-manage php.ini (all the ini variables below are then ignored).

    php_fpm_pool_user: "[apache|www-data|other]" # default varies by OS
    php_fpm_pool_group: "[apache|www-data|other]" # default varies by OS
    php_memory_limit: "256M"
    php_max_execution_time: "60"
    php_max_input_time: "60"
    php_max_input_vars: "1000"
    php_realpath_cache_size: "32K"
    php_file_uploads: "On"
    php_upload_max_filesize: "64M"
    php_max_file_uploads: "20"
    php_post_max_size: "32M"
    php_date_timezone: "America/Chicago"
    php_allow_url_fopen: "On"
    php_cgi_fix_pathinfo: 1
    php_sendmail_path: "/usr/sbin/sendmail -t -i"
    php_output_buffering: "4096"
    php_short_open_tag: "Off"
    php_error_reporting: "E_ALL & ~E_DEPRECATED & ~E_STRICT"
    php_display_errors: "Off"
    php_display_startup_errors: "Off"
    php_expose_php: "On"
    php_session_cookie_lifetime: 0
    php_session_gc_probability: 1
    php_session_gc_divisor: 1000
    php_session_gc_maxlifetime: 1440
    php_session_save_handler: files
    php_session_save_path: ''
    php_disable_functions: []
    php_precision: 14
    php_serialize_precision: "-1"

Various php.ini defaults, used only when `php_use_managed_ini` is `true`.

### OpCache-related Variables

    php_opcache_zend_extension: "opcache.so"
    php_opcache_enable: "1"
    php_opcache_enable_cli: "0"
    php_opcache_memory_consumption: "96"
    php_opcache_interned_strings_buffer: "16"
    php_opcache_max_accelerated_files: "4096"
    php_opcache_max_wasted_percentage: "5"
    php_opcache_validate_timestamps: "1"
    php_opcache_revalidate_path: "0"
    php_opcache_revalidate_freq: "2"
    php_opcache_max_file_size: "0"
    php_opcache_blacklist_filename: ""

Commonly customized OpCache directives. Make sure the memory
(`php_opcache_memory_consumption`, in MB) and file slots
(`php_opcache_max_accelerated_files`) can hold all the PHP code you run, or performance
suffers. For a custom opcache.so location, give the full path in
`php_opcache_zend_extension`.

    php_opcache_conf_filename: [platform-specific]

The platform-specific OpCache configuration filename; the default usually works.

### APCu-related Variables

    php_enable_apc: true

Whether to enable APCu; the other APC variables do nothing when false.

    php_apc_shm_size: "96M"
    php_apc_enable_cli: "0"

Size `php_apc_shm_size` to hold all cache entries with some headroom — APCu running out
of memory slows PHP dramatically.

    php_apc_conf_filename: [platform-specific]

The platform-specific APCu configuration filename; the default usually works.

If you customize `php_packages`, keep the APCu package in the list: `php-pecl-apcu` on
RHEL-family, `php-apcu` on Debian/Ubuntu.

### Installing from Source

For a PHP version no package provides (or PHP master), compile from source — note this
takes far longer than packages (5+ minutes on a modern quad-core).

    php_install_from_source: false

Set `true` to build from source instead of packages.

    php_source_repo: "https://github.com/php/php-src.git"
    php_source_version: "master"

Repository and git branch/tag/commit to build.

    php_source_clone_dir: "~/php-src"
    php_source_clone_depth: 1
    php_source_install_path: "/opt/php"
    php_source_install_gmp_path: "/usr/include/x86_64-linux-gnu/gmp.h"
    php_source_mysql_config: "/usr/bin/mysql_config"

Clone/install locations, the GMP header path (platform-specific), and the
`mysql_config` binary (may be `mariadb_config` on newer systems).

    php_source_make_command: "make"

Use `make --jobs=X` (X = core count) to speed up compilation dramatically.

    php_source_configure_command: >
      [...]

The `./configure` command that builds the Makefile — add the options your environment
needs (folded scalar `>` keeps it readable). Webserver-specific notes:

- **Apache with mpm_prefork**: ensure `apxs2` is available (e.g. `apache2-prefork-dev`
  on Ubuntu), add `--with-apxs2`, and load `mpm_prefork` plus a PHP module config.
- **Apache with mpm_event/worker or Nginx**: compile with `--enable-fpm` and run PHP-FPM.

## Dependencies

None.

## Example Playbook

    - hosts: webservers
      vars:
        php_memory_limit: "128M"
        php_max_execution_time: "90"
        php_upload_max_filesize: "256M"
      roles:
        - startcloud.startcloud_roles.php_versions
        - startcloud.startcloud_roles.php

## License

GPL-2.0-or-later
