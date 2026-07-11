# Ansible Role: MySQL

Installs and configures a MySQL or MariaDB server on Debian/Ubuntu, RHEL-family, or Arch
Linux. On Debian/Ubuntu the official MySQL APT repository (mysql-apt-config, MySQL 8.0)
is set up first; RHEL-family systems install their platform packages (MariaDB on stock
EL). The role manages the global my.cnf, secure-installation steps (root password,
anonymous users, test database), databases, users, and optional master/slave
replication.

## Requirements

This role requires root access, so either run it in a playbook with a global
`become: true`, or invoke the role like:

    - hosts: database
      roles:
        - role: startcloud.startcloud_roles.mysql
          become: true

The `community.mysql` collection provides the modules used here — install it with
`ansible-galaxy collection install community.mysql` if you run bare ansible-core.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    mysql_user_home: /root
    mysql_user_name: root
    mysql_user_password: root

The home directory inside which Python MySQL settings will be stored, which Ansible
uses when connecting to MySQL. This should be the home of the user running the role;
`mysql_user_name`/`mysql_user_password` support running under a non-root account.

    mysql_root_home: /root
    mysql_root_username: root
    mysql_root_password: root

The MySQL root user account details.

    mysql_root_password_update: false

Whether to force an update of the root password. By default the password is only set
when MySQL is first configured.

> Note: If you get `ERROR 1045 (28000): Access denied for user 'root'@'localhost'`
> after a failed or interrupted run, the root password likely wasn't updated to begin
> with. Remove or edit the `.my.cnf` inside `mysql_user_home` (set `password=''`), run
> again with `mysql_root_password_update: true`, and setup should complete.

    mysql_enabled_on_startup: true

Whether MySQL should be enabled on startup.

    mysql_config_file: [OS-specific]
    mysql_config_include_dir: [OS-specific]

The main my.cnf configuration file and include directory.

    overwrite_global_mycnf: true

Whether the global my.cnf is overwritten each run. Leave `true` to keep MySQL
configured from this role's variables.

    mysql_config_include_files: []

Files that override the global my.cnf, each with a `src` path and optional `force`.

    mysql_databases: []

Databases to create: `name` plus optional `encoding` (utf8), `collation`
(utf8_general_ci), `replicate` (1, used only with replication), and `state`
(present/absent).

    mysql_users: []

Users and their privileges: `name`, `host` (localhost), `password` (plaintext or
encrypted with `encrypted: true`), `priv` (`*.*:USAGE`), `append_privs`, `state`.

    mysql_packages: [OS-specific]

Packages installed per platform (see `vars/`). Add extras like `mysql-devel` if needed.

    mysql_enablerepo: ""

(RHEL-family only) Comma-separated additional repositories to enable during install
(e.g. `remi,epel`).

    mysql_python_package_debian: python3-mysqldb

(Debian/Ubuntu only) The MySQL Python client package.

    mysql_port: "3306"
    mysql_bind_address: '0.0.0.0'
    mysql_skip_name_resolve: false
    mysql_datadir: /var/lib/mysql
    mysql_socket: [OS-specific]
    mysql_pid_file: [OS-specific]

MySQL connection configuration.

    mysql_log_file_group: mysql   # adm on Debian
    mysql_log: ""
    mysql_log_error: [OS-specific]
    mysql_syslog_tag: [OS-specific]

Logging configuration. Setting `mysql_log` (general query log) or `mysql_log_error` to
`syslog` makes MySQL log to syslog with `mysql_syslog_tag`.

    mysql_slow_query_log_enabled: false
    mysql_slow_query_log_file: [OS-specific]
    mysql_slow_query_time: "2"

Slow query log settings. The log file is created by this role; on SELinux/AppArmor
systems you may need to permit the path for MySQL.

    mysql_key_buffer_size: "256M"
    mysql_max_allowed_packet: "64M"
    mysql_table_open_cache: "256"
    ...

The remaining settings in `defaults/main.yml` control memory usage and common tuning.
Defaults are sized for ~512 MB of RAM available to MySQL — adjust for your server.

    mysql_disable_log_bin: false

When true (and not a replication master), disables the binary log to save disk space.

    mysql_server_id: "1"
    mysql_max_binlog_size: "100M"
    mysql_binlog_format: "ROW"
    mysql_expire_logs_days: "10"
    mysql_replication_role: ''
    mysql_replication_master: ''
    mysql_replication_user: []

Replication settings. Set `mysql_server_id` and `mysql_replication_role` per server
(master = ID 1 / role `master`; slave = ID 2 / role `slave`). `mysql_replication_user`
uses the same keys as `mysql_users` entries; it is created on the master and used by
the slaves. `mysql_replication_master` must resolve to an address the slaves can reach.
If the master is reached differently from where Ansible runs, set
`mysql_replication_master_inventory_host`.

    mysql_hide_passwords: false

Hide task output that would contain passwords.

### MariaDB usage

The role works with either MySQL or a compatible MariaDB. On stock RHEL/CentOS the
mariadb engine is the default package; all variables still reference 'mysql'.

## Dependencies

None (the `community.mysql` collection must be available — see Requirements).

## Example Playbook

    - hosts: db-servers
      become: true
      vars:
        mysql_root_password: super-secure-password
        mysql_databases:
          - name: example_db
            encoding: latin1
            collation: latin1_general_ci
        mysql_users:
          - name: example_user
            host: "%"
            password: similarly-secure-password
            priv: "example_db.*:ALL"
      roles:
        - startcloud.startcloud_roles.mysql

## License

GPL-2.0-or-later
