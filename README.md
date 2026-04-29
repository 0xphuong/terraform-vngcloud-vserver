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
  source = "github.com/0xphuong/terraform-vngcloud-vserver?ref=v1.1.0"

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

### Complete — multiple groups with overrides

```hcl
module "vserver" {
  source = "github.com/0xphuong/terraform-vngcloud-vserver?ref=v1.1.0"

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
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 100
        security_group = [var.app_sg_id]
        overrides = {
          "0" = { flavor_id = var.flavor_8cpu_16gb, root_disk_size = 80 }  # master
        }
      }
      mongodb = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 200
        security_group = [var.db_sg_id]
        overrides = {
          "0" = { data_disk_size = 500 }  # primary — bigger disk
        }
      }
    }
  }
}
```

## Overrides — per-node config

`overrides` là map dùng index (dạng string `"0"`, `"1"`, ...) để override config của từng node cụ thể trong group. Field nào không khai báo trong override sẽ dùng giá trị default của group.

### Use case 1 — Tất cả node đồng nhất (không cần overrides)

```hcl
app = {
  count          = 3
  flavor_id      = "flv-4cpu-8gb"
  root_disk_size = 40
  data_disk_size = 100
  security_group = ["sg-app"]
  # app-0, app-1, app-2 → cùng config
}
```

### Use case 2 — Master/worker pattern

```hcl
app = {
  count          = 3
  flavor_id      = "flv-4cpu-8gb"   # worker default
  root_disk_size = 40
  security_group = ["sg-app"]
  overrides = {
    "0" = { flavor_id = "flv-8cpu-16gb", root_disk_size = 80 }  # app-0 là master
  }
  # app-0 → flv-8cpu-16gb / 80GB
  # app-1, app-2 → flv-4cpu-8gb / 40GB
}
```

### Use case 3 — Override 1 field (primary node disk lớn hơn)

```hcl
mongodb = {
  count          = 3
  flavor_id      = "flv-4cpu-8gb"
  root_disk_size = 40
  data_disk_size = 200
  security_group = ["sg-db"]
  overrides = {
    "0" = { data_disk_size = 500 }  # mongodb-0 là primary
  }
  # mongodb-0 → data_disk 500 GB
  # mongodb-1, mongodb-2 → data_disk 200 GB
}
```

### Use case 4 — Nhiều node override hoàn toàn khác nhau

```hcl
elasticsearch = {
  count          = 3
  flavor_id      = "flv-4cpu-8gb"   # data node default
  root_disk_size = 40
  data_disk_size = 300
  security_group = ["sg-es"]
  overrides = {
    "0" = { flavor_id = "flv-2cpu-4gb", root_disk_size = 20, data_disk_size = 0 }  # master
    "1" = { flavor_id = "flv-2cpu-4gb", root_disk_size = 20, data_disk_size = 0 }  # master
  }
  # es-0, es-1 → master node (no data disk)
  # es-2 → data node (300 GB disk)
}
```

### Use case 5 — Override floating IP cho 1 node

```hcl
bastion = {
  count          = 2
  flavor_id      = "flv-2cpu-2gb"
  root_disk_size = 20
  security_group = ["sg-bastion"]
  floating       = false
  overrides = {
    "0" = { floating = true }  # bastion-0 có public IP
  }
  # bastion-0 → floating IP
  # bastion-1 → internal only
}
```

### Use case 6 — Override zone_id per node (spread across zones)

```hcl
redis = {
  count          = 3
  flavor_id      = "flv-2cpu-4gb"
  root_disk_size = 20
  data_disk_size = 50
  security_group = ["sg-db"]
  floating       = false
  zone_id        = "HCM03-1A"   # default zone
  overrides = {
    "1" = { zone_id = "HCM03-1B" }  # redis-1 sang zone B
  }
  # redis-0 → HCM03-1A
  # redis-1 → HCM03-1B
  # redis-2 → HCM03-1A
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| vngcloud | >= 1.3.11 |
| cloudinit | >= 2.3.0 |

## Providers

| Name | Version |
|------|---------|
| vngcloud | >= 1.3.11 |
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
| project\_id | VNG Cloud project ID | `string` | — | **yes** |
| cloud\_init | Cloud-init bootstrap config | `object` | — | **yes** |
| servers | Shared server params + per-server configs | `object` | — | **yes** |
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
| `data_disk_type_id` | `string` | `null` | Data disk type (required if any group uses data disk) |
| `server_group_id` | `string` | `null` | Server group for placement |
| `server_configs` | `map(object)` | — | Per-group server config |

### `server_configs` map value

| Field | Type | Default | Required | Description |
|-------|------|---------|----------|-------------|
| `count` | `number` | — | **yes** | Number of servers in group |
| `flavor_id` | `string` | — | **yes** | Default instance flavor (CPU/RAM) |
| `root_disk_size` | `number` | — | **yes** | Default root disk size in GB (min 20) |
| `security_group` | `list(string)` | — | **yes** | Default security group IDs |
| `floating` | `bool` | `false` | no | Default: attach floating IP |
| `data_disk_size` | `number` | `0` | no | Default data disk size in GB (0 = no disk) |
| `zone_id` | `string` | `null` | no | Default zone for all nodes in group (e.g. `HCM03-1A`) |
| `overrides` | `map(object)` | `{}` | no | Per-node config overrides, key = node index as string |

### `overrides` map value (all fields optional)

| Field | Type | Description |
|-------|------|-------------|
| `flavor_id` | `string` | Override flavor for this node |
| `root_disk_size` | `number` | Override root disk size for this node |
| `security_group` | `list(string)` | Override security groups for this node |
| `floating` | `bool` | Override floating IP for this node |
| `data_disk_size` | `number` | Override data disk size for this node |
| `zone_id` | `string` | Override zone for this node |

## Outputs

| Name | Description |
|------|-------------|
| server\_ids | Map of server key => server ID |
| server\_ips | Map of server key => internal IP |
| server\_floating\_ips | Map of server key => floating IP |
| server\_names | Map of server key => server name |
| volume\_ids | Map of volume key => volume ID (only servers with data disk) |
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
