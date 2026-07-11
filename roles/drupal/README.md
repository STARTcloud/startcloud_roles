# Ansible Role: Drupal

Deploys, builds, and installs [Drupal](https://drupal.org/), an open source content
management platform. Four strategies are supported and gated by variables: deploy from a
Git repository, build from a Drush make file, build from an existing `composer.json`, or
scaffold a new site with `composer create-project` (the default). The site can then be
installed with Drush.

## Requirements

Drupal is a PHP-based application meant to run behind a typical LAMP/LEMP stack, so
you'll need at least:

- Apache or Nginx (`startcloud.startcloud_roles.apache` or
  `startcloud.startcloud_roles.nginx`)
- MySQL or a similar database server (`startcloud.startcloud_roles.mysql` or
  `startcloud.startcloud_roles.postgresql`)
- PHP (`startcloud.startcloud_roles.php`, paired with
  `startcloud.startcloud_roles.php_versions`)
- Composer (`startcloud.startcloud_roles.composer`) for the Composer-based strategies

Drush is required if this role installs the site (`drupal_install_site: true`); the
default `drupal_composer_dependencies` pulls `drush/drush` into the project, and a
project-local `vendor/bin/drush` is preferred automatically when present. Git is
required when deploying from a repository (`drupal_deploy: true`).

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

### Deploy an existing project with Git

    drupal_deploy: false
    drupal_deploy_repo: ""
    drupal_deploy_version: master
    drupal_deploy_update: true
    drupal_deploy_dir: "/var/www/drupal"
    drupal_deploy_accept_hostkey: false

Set `drupal_deploy` to `true` and `drupal_build_composer*` to `false` to deploy Drupal
from an existing Git repository. `version` can be a branch, tag, or commit hash;
`update` controls whether a branch checkout is updated to the latest commit;
`accept_hostkey` auto-accepts the Git server's hostkey on first connection. When the
checkout picks up new commits and a site already exists, database updates and a cache
rebuild are run automatically.

    drupal_deploy_composer_install: true

Whether a `composer install` runs after the Git checkout finishes (when a
`composer.json` is present).

### Build a project from a Drush Make file

    drupal_build_makefile: false
    drush_makefile_path: "/path/to/drupal.make.yml"
    drush_make_options: "--no-gitinfofile"

Set this to `true` and `drupal_build_composer*` to `false` to build from a Drush make
file.

### Build a project from a Composer file

    drupal_build_composer: false
    drupal_composer_path: "/path/to/drupal.composer.json"
    drupal_composer_install_dir: "{{ drupal_deploy_dir }}"
    drupal_composer_no_dev: true
    drupal_composer_dependencies:
      - "drush/drush:^10.1"

Set `drupal_build_makefile` to `false` and this to `true` for a Composer-file-based
deployment.

    drupal_composer_bin_dir: "vendor/bin"

If your project's `composer.json` sets `bin-dir` to something other than `vendor/bin`,
override this with the same path.

### Create a new project using composer create-project

    drupal_build_composer_project: true
    drupal_composer_project_package: "drupal/recommended-project:^9@dev"
    drupal_composer_project_options: "--prefer-dist --stability dev --no-interaction"

The default strategy: scaffold a fresh site with Composer's `create-project`.

### Required Drupal site settings

    drupal_core_path: "{{ drupal_deploy_dir }}/web"
    drupal_core_owner: "{{ ansible_ssh_user | default(ansible_env.SUDO_USER, true) | default(ansible_env.USER, true) | default(ansible_user_id) }}"
    drupal_core_owner_become: false

The path to Drupal's docroot and its ownership. If Ansible doesn't run as the user that
should own the core path, set `drupal_core_owner` and `drupal_core_owner_become: true`.

    drupal_db_user: drupal
    drupal_db_password: drupal
    drupal_db_name: drupal
    drupal_db_backend: mysql
    drupal_db_host: "127.0.0.1"

Database settings used in the Drush `--db-url`. `pgsql` is also supported (a
`bytea_output` fix is applied automatically on PostgreSQL). Use a secure
`drupal_db_password` outside of local development.

### Drupal site installation options

    drupal_install_site: true

Set to `false` if you don't need `drush site-install` (e.g. you copy down a database
with `drush sql-sync` instead).

    drupal_domain: "drupaltest.test"
    drupal_site_name: "Drupal"
    drupal_install_profile: standard
    drupal_site_install_extra_args: []
    drupal_enable_modules: []
    drupal_account_name: admin
    drupal_account_pass: admin

Settings used when installing the site. Extra `drush site-install` arguments go in
`drupal_site_install_extra_args` as a list; `drupal_enable_modules` are enabled with
`drush pm-enable` after install.

## Dependencies

None.

## Example Playbook

    - hosts: webserver
      vars:
        drupal_install_site: true
        drupal_build_composer_project: true
        drupal_composer_install_dir: "/var/www/drupal"
        drupal_core_path: "{{ drupal_composer_install_dir }}/web"
        drupal_domain: "example.com"
      roles:
        - startcloud.startcloud_roles.apache
        - startcloud.startcloud_roles.mysql
        - startcloud.startcloud_roles.php_versions
        - startcloud.startcloud_roles.php
        - startcloud.startcloud_roles.composer
        - startcloud.startcloud_roles.drupal

## License

GPL-2.0-or-later
