# Changelog

All notable changes to this module will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2026-04-29

### Added
- `enabled` field in `server_configs` — `optional(bool, true)`. Set `false` to destroy all servers in a group without removing the config block
- Validation updated: `count >= 1` only enforced when `enabled = true`
- Use case 6: disable/enable a server group with `enabled = false/true`

## [1.2.0] - 2026-04-29

### Added
- `zone_id` field in `server_configs` (Optional) — default zone for all nodes in a group
- `zone_id` field in `overrides` (Optional) — override zone per individual node
- Use case 6: spread nodes across zones via `zone_id` override

### Changed
- Provider version constraint bumped: `>= 1.2.7` → `>= 1.3.11`
- Examples: ref bumped to `v1.2.0`

## [1.1.0] - 2026-04-29

### Added
- `overrides` field in `server_configs` — per-node config overrides using node index as key (e.g. `"0"`, `"1"`)
- Supported override fields: `flavor_id`, `root_disk_size`, `security_group`, `floating`, `data_disk_size`
- `locals` uses `try()` + null-check pattern to merge overrides with group defaults
- 5 documented use cases: identical nodes, master/worker, single-field override, multi-node override, floating IP override
- Examples: source URLs updated from `binhphuongit` → `0xphuong`, ref bumped to `v1.1.0`

### Changed
- `server_configs` object: `overrides` added as `optional(map(object(...)), {})` — fully backward compatible

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
