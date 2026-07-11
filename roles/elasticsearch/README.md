# Ansible Role: Elasticsearch

Installs Elasticsearch on Debian/Ubuntu or RHEL-family systems from the official Elastic
repositories, renders the node configuration and JVM heap options, restarts on config
changes, and waits until the HTTP port is reachable.

## Requirements

Java 8 or newer must be available on the host.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

    run_tasks: true

Master gate — when false the role loads its variables but runs no tasks.

    elasticsearch_version: '7.x'

The major version branch to use when installing Elasticsearch (also selects the Elastic
package repository).

    elasticsearch_package: elasticsearch

Keep the default to follow the latest release in the `elasticsearch_version` cycle, or
pin a version with `-7.13.2` (RHEL) / `=7.13.2` (Debian).

    elasticsearch_package_state: present

The package state; set to `latest` to upgrade or change versions.

    elasticsearch_service_state: started
    elasticsearch_service_enabled: true

Controls the Elasticsearch service options.

    elasticsearch_network_host: localhost

Network host to listen on. Change to a specific IP to listen on one interface, or
`"0.0.0.0"` for all interfaces. For a single-node setup listening on multiple
interfaces, also add `discovery.type: single-node` to `elasticsearch_extra_options`.

    elasticsearch_http_port: 9200

The port to listen on for HTTP connections.

    elasticsearch_heap_size_min: 1g
    elasticsearch_heap_size_max: 2g

The JVM heap bounds — written to `jvm.options` on Elasticsearch 6 and below, or
`jvm.options.d/heap.options` on 7 and above.

    elasticsearch_extra_options: ''

Arbitrary configuration appended as-is to the end of `elasticsearch.yml`. Preserve
formatting with a block scalar:

    elasticsearch_extra_options: |  # Don't forget the pipe!
      some.option: true
      another.option: false

## Dependencies

None.

## Example Playbook

    - hosts: search
      roles:
        - startcloud.startcloud_roles.elasticsearch

## License

GPL-2.0-or-later
