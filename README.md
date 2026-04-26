# terraform-vngcloud-vserver

Terraform module to provision **vServer instances**, **data volumes**, and **volume attachments** on [VNG Cloud](https://vngcloud.vn).

## Features

- Multi-server provisioning using a single `servers` variable (map-based config)
- Optional data disk per server group (automatically attached)
- Cloud-init bootstrap: admin user, SSH key, port, password — all templated (no hardcoded secrets)
- Supports floating IP (public IP) per server
- Server group placement support
- Structured outputs: IDs, IPs, floating IPs, volume IDs

## Usage

### Basic — 1 server

```hcl
module "vserver" {
  source = "github.com/binhphuongit/terraform-vngcloud-vserver?ref=v1.0.0"

  project_id = "pro-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  cloud_init = {
    admin_password     = var.admin_password
    ssh_authorized_key = var.ssh_public_key
  }

  servers = {
    encryption_volume = false
    image_id          = "img-xxxxxxxx"
    network_id        = "net-xxxxxxxx"
    subnet_id         = "sub-xxxxxxxx"
    root_disk_type_id = "vtype-xxxxxxxx"

    server_configs = {
      web = {
        count          = 1
        flavor_id      = "flav-xxxxxxxx"
        root_disk_size = 20
        security_group = ["secg-xxxxxxxx"]
        floating       = true
      }
    }
  }
}
```

### Complete — multiple server groups with data disks

```hcl
module "vserver" {
  source = "github.com/binhphuongit/terraform-vngcloud-vserver?ref=v1.0.0"

  project_id = var.project_id

  cloud_init = {
    admin_user         = "stackops"
    admin_password     = var.admin_password
    ssh_authorized_key = var.ssh_public_key
    ssh_port           = 234
  }

  servers = {
    encryption_volume = true
    image_id          = var.ubuntu_2004_image_id
    network_id        = var.network_id
    subnet_id         = var.private_subnet_id
    root_disk_type_id = var.nvme_disk_type_id
    data_disk_type_id = var.nvme_disk_type_id

    server_configs = {
      app = {
        count          = 2
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 100
        security_group = [var.app_sg_id]
      }
      mongodb = {
        count          = 1
        flavor_id      = var.flavor_2cpu_4gb
        root_disk_size = 20
        data_disk_size = 200
        security_group = [var.db_sg_id]
      }
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| vngcloud | >= 1.2.7 |
| cloudinit | >= 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| vngcloud | >= 1.2.7 |
| cloudinit | >= 2.3.0 |

## Resources

| Name | Type |
|------|------|
| vngcloud_vserver_server.this | resource |
| vngcloud_vserver_volume.this | resource |
| vngcloud_vserver_volume_attach.this | resource |
| cloudinit_config.this | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project\_id | VNG Cloud project ID | `string` | — | yes |
| cloud\_init | Cloud-init bootstrap config (admin user, password, SSH key, port) | `object` | — | yes |
| servers | Shared server params + per-server configs | `object` | — | yes |
| user\_data\_base64\_encode | Gzip + base64 encode user\_data | `bool` | `false` | no |

### `cloud_init` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `admin_user` | `string` | `"stackops"` | Admin username |
| `admin_password` | `string` | — | Admin password (sensitive) |
| `ssh_authorized_key` | `string` | — | SSH public key |
| `ssh_port` | `number` | `234` | SSH port |

### `servers` object

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `encryption_volume` | `bool` | — | Encrypt root disk |
| `image_id` | `string` | — | OS image ID |
| `network_id` | `string` | — | VPC network ID |
| `subnet_id` | `string` | — | Subnet ID |
| `root_disk_type_id` | `string` | — | Root disk type |
| `data_disk_type_id` | `string` | `null` | Data disk type |
| `server_group_id` | `string` | `null` | Server group for placement |
| `server_configs` | `map(object)` | — | Per-group server config |

### `server_configs` map value

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `count` | `number` | — | Number of servers in group |
| `flavor_id` | `string` | — | Instance flavor (CPU/RAM) |
| `root_disk_size` | `number` | — | Root disk size in GB (min 20) |
| `security_group` | `list(string)` | — | Security group IDs |
| `floating` | `bool` | `false` | Attach floating (public) IP |
| `data_disk_size` | `number` | `0` | Data disk size in GB (0 = no disk) |

## Outputs

| Name | Description |
|------|-------------|
| server\_ids | Map of server key => server ID |
| server\_ips | Map of server key => internal IP |
| server\_floating\_ips | Map of server key => floating IP |
| server\_names | Map of server key => server name |
| volume\_ids | Map of volume key => volume ID |
<!-- END_TF_DOCS -->

## Examples

- [Basic](./examples/basic) — 1 web server with floating IP
- [Complete](./examples/complete) — multiple server groups with data disks

## Security

- `cloud_init` is marked `sensitive = true` — values will not appear in Terraform output
- Never hardcode `admin_password` or `ssh_authorized_key` in `.tf` files
- Pass secrets via `terraform.tfvars` (gitignored) or environment variables:

```bash
export TF_VAR_admin_password="your-password"
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md).

## Changelog

See [CHANGELOG.md](./CHANGELOG.md).

## License

[MIT](./LICENSE)
