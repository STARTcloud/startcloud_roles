# Ansible Role: PostgreSQL

Installs and configures a PostgreSQL server on Debian/Ubuntu, RHEL-family, or Arch
systems: packages and the psycopg2 library, cluster initialization, `postgresql.conf`
options and `pg_hba.conf` entries, plus the requested databases and users.

## Requirements

No special requirements; note that this role requires root access, so either run it in a
playbook with a global `become: true`, or invoke the role like:

    - hosts: database
      roles:
        - role: startcloud.startcloud_roles.postgresql
          become: true

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    postgresql_enablerepo: ""

(RHEL/CentOS only) A repo to use for the PostgreSQL installation.

    postgresql_restarted_state: "restarted"

State applied to the service when configuration changes — `restarted` or `reloaded`.

    postgresql_python_library: python-psycopg2

Library used by Ansible to communicate with PostgreSQL. Modern OS variable files switch
this to `python3-psycopg2` automatically.

    postgresql_user: postgres
    postgresql_group: postgres

The user and group under which PostgreSQL runs.

    postgresql_auth_method: "{{ ansible_fips | ternary('scram-sha-256', 'md5') }}"

Password auth method used in the default host-based auth entries — `scram-sha-256` on
FIPS-enabled systems, `md5` otherwise. When set to `scram-sha-256`, user passwords are
encrypted accordingly.

    postgresql_unix_socket_directories:
      - /var/run/postgresql

The directories (usually one, but can be multiple) where PostgreSQL's socket is created.

    postgresql_service_state: started
    postgresql_service_enabled: true

State of the postgresql service and whether it starts at boot.

    postgresql_global_config_options:
      - option: unix_socket_directories
        value: '{{ postgresql_unix_socket_directories | join(",") }}'
      - option: log_directory
        value: 'log'

Global options set in `postgresql.conf`. If `log_directory` is overridden with another
path (relative or absolute), the role creates it.

    postgresql_hba_entries:
      - { type: local, database: all, user: postgres, auth_method: peer }
      - { type: local, database: all, user: all, auth_method: peer }
      - { type: host, database: all, user: all, address: '127.0.0.1/32', auth_method: "{{ postgresql_auth_method }}" }
      - { type: host, database: all, user: all, address: '::1/128', auth_method: "{{ postgresql_auth_method }}" }

Host-based authentication entries rendered into `pg_hba.conf`. Entry options: `type`,
`database`, `user`, `auth_method` (required); `address` or `ip_address`+`ip_mask`;
`auth_options` (optional). When overriding, copy the existing defaults you want to keep.

    postgresql_locales:
      - 'en_US.UTF-8'

(Debian/Ubuntu only) Locales generated for PostgreSQL databases.

    postgresql_databases:
      - name: exampledb # required; the rest are optional
        lc_collate: # defaults to 'en_US.UTF-8'
        lc_ctype: # defaults to 'en_US.UTF-8'
        encoding: # defaults to 'UTF-8'
        template: # defaults to 'template0'
        login_host: # defaults to 'localhost'
        login_password: # defaults to not set
        login_user: # defaults to '{{ postgresql_user }}'
        login_unix_socket: # defaults to 1st of postgresql_unix_socket_directories
        port: # defaults to not set
        owner: # defaults to postgresql_user
        state: # defaults to 'present'

Databases to ensure exist. Only `name` is required.

    postgresql_users:
      - name: jdoe # required; the rest are optional
        password: # defaults to not set
        encrypted: # defaults to not set
        priv: # defaults to not set
        role_attr_flags: # defaults to not set
        db: # defaults to not set
        login_host: # defaults to 'localhost'
        login_password: # defaults to not set
        login_user: # defaults to '{{ postgresql_user }}'
        login_unix_socket: # defaults to 1st of postgresql_unix_socket_directories
        port: # defaults to not set
        state: # defaults to 'present'

Users to ensure exist. Only `name` is required.

    postgres_users_no_log: false

Whether to suppress user data (which may contain passwords) in task output.

    postgresql_version: [OS-specific]
    postgresql_data_dir: [OS-specific]
    postgresql_bin_path: [OS-specific]
    postgresql_config_path: [OS-specific]
    postgresql_daemon: [OS-specific]
    postgresql_packages: [OS-specific]

OS-specific variables set by files in `vars/`. Only override these when using a
PostgreSQL build that didn't come from system packages.

## Dependencies

None.

## Example Playbook

    - hosts: database
      become: true
      vars:
        postgresql_databases:
          - name: example_db
        postgresql_users:
          - name: example_user
            password: supersecure
      roles:
        - startcloud.startcloud_roles.postgresql

## License

GPL-2.0-or-later
