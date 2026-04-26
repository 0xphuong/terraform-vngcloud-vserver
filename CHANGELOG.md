# Changelog

All notable changes to this module will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-04-26

### Added
- Initial release
- `vngcloud_vserver_server` resource with `for_each` support for multi-server provisioning
- `vngcloud_vserver_volume` resource for optional data disk per server
- `vngcloud_vserver_volume_attach` resource to attach data disks
- Cloud-init bootstrap via `hashicorp/cloudinit` provider (replaces deprecated `hashicorp/template`)
- `cloud-config.tpl` with templated admin user, password, SSH key, and SSH port
- Input validation: count >= 1, root_disk_size >= 20 GB, password length, port range
- Outputs: `server_ids`, `server_ips`, `server_floating_ips`, `server_names`, `volume_ids`
- Examples: `basic`, `complete`
- GitHub Actions CI: fmt, validate, tflint, docs check

### Changed
- `required_providers.tf` renamed to `versions.tf`
- `cloud-config.tpl` SSH key and password moved from hardcoded to template variables
- `data.tf` migrated from deprecated `hashicorp/template` to `hashicorp/cloudinit`
- `outputs.tf` changed from string list to structured maps
