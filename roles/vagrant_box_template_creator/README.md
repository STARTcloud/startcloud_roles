# vagrant_box_template_creator

Ansible role `vagrant_box_template_creator` for the `startcloud.startcloud_roles` collection.

## NOT IN USE — aspirational, untested

This role was an experiment in driving the whole VBTC build/package/publish
cycle as an Ansible role. It has never been part of the production workflow
and its template catalog (`vars/template_definitions.yml`) duplicates facts
the template JSONs already own, so it drifts.

Do not build on it. The real, in-use workflow is the raw `packer build`
command sequence documented in the
[vagrant_box_template_creator repository README](https://github.com/STARTcloud/vagrant_box_template_creator):
build via `provisioners/packer/*.json`, then per-provider
`providers/<provider>/package.json` and `publish.json`.
