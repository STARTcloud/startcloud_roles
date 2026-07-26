# Ansible role for MongoDB
![Centos](https://github.com/UnderGreen/ansible-role-mongodb/actions/workflows/centos.yml/badge.svg) ![Debian](https://github.com/UnderGreen/ansible-role-mongodb/actions/workflows/debian.yml/badge.svg) ![Ubuntu](https://github.com/UnderGreen/ansible-role-mongodb/actions/workflows/ubuntu.yml/badge.svg) ![Amazon Linux 2](https://github.com/UnderGreen/ansible-role-mongodb/actions/workflows/amazonlinux2.yml/badge.svg)

Ansible role to install and manage [MongoDB](http://www.mongodb.org/).

- Install and configure the MongoDB
- Configure mongodb users
- Configure authentication
- Configure replication
- Setup MMS automation agent;

MongoDB support matrix:

| Distribution   |    MongoDB 7.0     |    MongoDB 8.0     |
| -------------- | :----------------: | :----------------: |
| Debian 12      | :white_check_mark: | :white_check_mark: |
| Ubuntu 22.04   | :white_check_mark: | :white_check_mark: |
| Ubuntu 24.04   | :white_check_mark: | :white_check_mark: |
| RHEL 8.x       | :white_check_mark: | :white_check_mark: |
| RHEL 9.x       | :white_check_mark: | :white_check_mark: |
| Amazon Linux 2 | :white_check_mark: | :white_check_mark: |

- :white_check_mark: - supported
- MongoDB releases before 7.0 have reached EOL and are rejected by the role.
- MongoDB 5.0 and newer require a CPU with AVX support.

#### Variables

```yaml
# This variable is used to set source of MongoDB installation.
# 'mongodb' - version provided by Debian-based distributions from their official package repositories.
# 'mongodb-org' - version provided by MongoDB package repository.
# 'mongodb' is not included in th role test matrix and working of it is not guarantied.
mongodb_package: mongodb-org

# `mongodb_version` variable sets version of MongoDB.
# Must be '7.0' or newer. The APT/YUM repository, the signing key URL and the
# /etc/apt/keyrings keyring path are all derived from this value.
mongodb_version: "8.0"

# Install PyMongo from the distribution packages by default; pip installs into
# the system interpreter fail on PEP 668 ("externally managed") systems.
mongodb_pymongo_from_pip: false
mongodb_pymongo_pip_version: # Choose PyMongo version to install from pip. If not set use latest
mongodb_user_update_password: "on_create" # MongoDB user password update default policy
mongodb_manage_service: true
mongodb_manage_systemd_unit: true

# Disable transparent hugepages on systemd debian based installations
mongodb_disable_transparent_hugepages: false

# You can enable or disable NUMA support
mongodb_use_numa: true

mongodb_user: "{{ 'mongod' if ('RedHat' == ansible_os_family) else 'mongodb' }}"
mongodb_uid:
mongodb_gid:
mongodb_daemon_name: "{{ 'mongod' if ('mongodb-org' in mongodb_package) else 'mongodb' }}"
## net Options
mongodb_net_bindip: 127.0.0.1 # Comma separated list of ip addresses to listen on
mongodb_net_ipv6: false # Enable IPv6 support (disabled by default)
mongodb_net_maxconns: 65536 # Max number of simultaneous connections
mongodb_net_port: 27017 # Specify port number

## net TLS Options
# net.ssl was removed in MongoDB 7.0 — mongod rejects it as an unknown option — so the
# role only writes the net.tls stanza. Any mode other than 'disabled' enables it.
mongodb_net_tls_mode: "disabled" # disabled / allowTLS / preferTLS / requireTLS
mongodb_net_tls_certificate_key_file: "" # PEM with the server certificate and its private key (net.tls.certificateKeyFile)
mongodb_net_tls_ca_file: "" # CA used to validate client certificates (net.tls.CAFile)
mongodb_net_tls_allow_connections_without_certificates: false # Accept clients that present no certificate
mongodb_net_tls_host: "" # Hostname clients use to reach this member; must match the server certificate

## processManagement Options
mongodb_processmanagement_fork: false # Fork server process

## security Options
# Disable or enable security. Possible values: 'disabled', 'enabled'
mongodb_security_authorization: "disabled"
mongodb_security_keyfile: /etc/mongodb-keyfile # Specify path to keyfile with password for inter-process authentication

## storage Options
mongodb_storage_dbpath: /data/db # Directory for datafiles
mongodb_storage_dirperdb: false # Use one directory per DB

# The storage engine for the mongod database.
# wiredTiger is the only engine supported by MongoDB 7.0 and newer.
mongodb_storage_engine: "wiredTiger"

# WiredTiger Options
mongodb_wiredtiger_cache_size: 1 # Cache size for wiredTiger in GB

## systemLog Options
## The destination to which MongoDB sends all log output. Specify either 'file' or 'syslog'.
## If you specify 'file', you must also specify mongodb_systemlog_path.
mongodb_systemlog_destination: "file"
mongodb_systemlog_logappend: true # Append to logpath instead of over-writing
mongodb_systemlog_path: /var/log/mongodb/{{ mongodb_daemon_name }}.log # Log file to send write to instead of stdout

## replication Options
mongodb_replication_replset: # Enable replication <setname>[/<optionalseedhostlist>]
mongodb_replication_oplogsize: 1024 # specifies a maximum size in megabytes for the replication operation log

## setParameter options
# Configure setParameter option.
# Example :
mongodb_set_parameters:
  {
    "enableLocalhostAuthBypass": "true",
    "authenticationMechanisms": "SCRAM-SHA-1,MONGODB-CR",
  }

## Extend config with arbitrary values
# Example :
mongodb_config:
  replication:
    - "enableMajorityReadConcern: false"

# MMS Agent
mongodb_mms_agent_pkg: https://cloud.mongodb.com/download/agent/monitoring/mongodb-mms-monitoring-agent_7.2.0.488-1_amd64.ubuntu1604.deb
mongodb_mms_group_id: ""
mongodb_mms_api_key: ""
mongodb_mms_base_url: https://mms.mongodb.com

# Log rotation
mongodb_logrotate: true # Rotate mongodb logs.
mongodb_logrotate_options:
  - compress
  - copytruncate
  - daily
  - dateext
  - rotate 7
  - size 10M

# password for inter-process authentication
# please regenerate this file on production environment with command 'openssl rand -base64 741'
mongodb_keyfile_content: |
  8pYcxvCqoe89kcp33KuTtKVf5MoHGEFjTnudrq5BosvWRoIxLowmdjrmUpVfAivh
  CHjqM6w0zVBytAxH1lW+7teMYe6eDn2S/O/1YlRRiW57bWU3zjliW3VdguJar5i9
  Z+1a8lI+0S9pWynbv9+Ao0aXFjSJYVxAm/w7DJbVRGcPhsPmExiSBDw8szfQ8PAU
  2hwRl7nqPZZMMR+uQThg/zV9rOzHJmkqZtsO4UJSilG9euLCYrzW2hdoPuCrEDhu
  Vsi5+nwAgYR9dP2oWkmGN1dwRe0ixSIM2UzFgpaXZaMOG6VztmFrlVXh8oFDRGM0
  cGrFHcnGF7oUGfWnI2Cekngk64dHA2qD7WxXPbQ/svn9EfTY5aPw5lXzKA87Ds8p
  KHVFUYvmA6wVsxb/riGLwc+XZlb6M9gqHn1XSpsnYRjF6UzfRcRR2WyCxLZELaqu
  iKxLKB5FYqMBH7Sqg3qBCtE53vZ7T1nefq5RFzmykviYP63Uhu/A2EQatrMnaFPl
  TTG5CaPjob45CBSyMrheYRWKqxdWN93BTgiTW7p0U6RB0/OCUbsVX6IG3I9N8Uqt
  l8Kc+7aOmtUqFkwo8w30prIOjStMrokxNsuK9KTUiPu2cj7gwYQ574vV3hQvQPAr
  hhb9ohKr0zoPQt31iTj0FDkJzPepeuzqeq8F51HB56RZKpXdRTfY8G6OaOT68cV5
  vP1O6T/okFKrl41FQ3CyYN5eRHyRTK99zTytrjoP2EbtIZ18z+bg/angRHYNzbgk
  lc3jpiGzs1ZWHD0nxOmHCMhU4usEcFbV6FlOxzlwrsEhHkeiununlCsNHatiDgzp
  ZWLnP/mXKV992/Jhu0Z577DHlh+3JIYx0PceB9yzACJ8MNARHF7QpBkhtuGMGZpF
  T+c73exupZFxItXs1Bnhe3djgE3MKKyYvxNUIbcTJoe7nhVMrwO/7lBSpVLvC4p3
  wR700U0LDaGGQpslGtiE56SemgoP

# names and passwords for administrative users
mongodb_user_admin_name: siteUserAdmin
mongodb_user_admin_password: passw0rd

mongodb_root_admin_name: siteRootAdmin
mongodb_root_admin_password: passw0rd

mongodb_root_backup_name: backupuser
mongodb_root_backup_password: passw0rd
```

#### Usage

Add `undergreen.mongodb` to your roles and set vars in your playbook file.

Example vars for authorization:

```yaml
mongodb_security_authorization: "enabled"
mongodb_users:
  - {
    name: testUser,
    password: passw0rd,
    roles: readWrite,
    database: app_development
}
```

Example vars for oplog user:

```yaml
mongodb_oplog_users:
  - {
    user: oplog,
    password: passw0rd
}
```

Required vars to change on production:

```yaml
mongodb_user_admin_password
mongodb_root_admin_password
mongodb_root_backup_password

# if you use replication and authorization
mongodb_security_keyfile
```

Example vars for replication:

```yaml
# It's a 'master' node
mongodb_login_host: 192.168.56.2

# mongodb_replication_params should be configured on each replica set node
mongodb_replication_params:
  - {
      host_name: 192.168.56.2,
      host_port: "{{ mongodb_net_port }}",
      host_type: replica,
    }
  # host_type can be replica(default) and arbiter
```

And inventory file for replica set:

```ini
[mongo_master]
192.158.56.2 mongodb_master=True # it is't a really master of MongoDB replica set,
                                 # use this variable for replica set init only
								 # or when master is moved from initial master node

[mongo_replicas]
192.168.56.3
192.168.56.4

[mongo:children]
mongo_master
mongo_replicas
```

Licensed under the GPLv2 License. See the [LICENSE.md](LICENSE.md) file for details.

#### Feedback, bug-reports, requests, ...

Are [welcome](https://github.com/UnderGreen/ansible-role-mongodb/issues)!
