module "vserver" {
  source = "github.com/0xphuong/terraform-vngcloud-vserver?ref=v1.5.0"

  project_id              = var.project_id
  user_data_base64_encode = false

  cloud_init = {
    admin_user         = "stackops"
    admin_password     = var.admin_password
    ssh_authorized_key = var.ssh_public_key
    ssh_port           = 234
  }

  servers = {
    encryption_volume = true
    image_id          = var.ubuntu_2004_image_id   # shared default image
    network_id        = var.network_id
    subnet_id         = var.private_subnet_id
    root_disk_type_id = var.nvme_disk_type_id       # shared default root disk type
    data_disk_type_id = var.nvme_disk_type_id       # shared default data disk type
    server_group_id   = var.server_group_id

    server_configs = {

      # ──────────────────────────────────────────────────────────────
      # Use case 1: All nodes identical (no overrides)
      # app-0, app-1, app-2 → same config, inherits shared image/disk types
      # ──────────────────────────────────────────────────────────────
      app = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 100
        security_group = [var.app_sg_id]
        floating       = false
        zone_id        = "HCM03-1A"
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 3: Override data_disk_type_id at group level
      # mongodb group uses SSD for data disk (overrides shared NVMe default)
      # mongodb-0 → 500 GB SSD data disk (primary)
      # mongodb-1, mongodb-2 → 200 GB SSD data disk (secondary)
      # ──────────────────────────────────────────────────────────────
      mongodb = {
        count             = 3
        flavor_id         = var.flavor_4cpu_8gb
        root_disk_size    = 40
        data_disk_size    = 200
        data_disk_type_id = var.ssd_disk_type_id   # override: SSD for this group
        security_group    = [var.db_sg_id]
        floating          = false
        zone_id           = "HCM03-1A"
        overrides = {
          "0" = { data_disk_size = 500 }   # primary — bigger disk, still SSD
        }
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 6: Override zone_id per node + root_disk_type_id at group level
      # redis group uses SSD root disk (overrides shared NVMe default)
      # redis-0 → HCM03-1A, redis-1 → HCM03-1B, redis-2 → HCM03-1A
      # ──────────────────────────────────────────────────────────────
      redis = {
        count             = 3
        flavor_id         = var.flavor_2cpu_4gb
        root_disk_size    = 20
        root_disk_type_id = var.ssd_disk_type_id   # override: SSD root disk for this group
        data_disk_size    = 50
        security_group    = [var.db_sg_id]
        floating          = false
        zone_id           = "HCM03-1A"
        overrides = {
          "1" = { zone_id = "HCM03-1B" }   # redis-1 sang zone B
        }
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 4: Override image_id at group level + per-node overrides
      # elasticsearch group uses Ubuntu 22.04 (overrides shared Ubuntu 20.04)
      # es-0, es-1 → master node (smaller flavor, no data disk, Ubuntu 22.04)
      # es-2       → data node (default flavor + 300 GB disk, Ubuntu 22.04)
      # es-3 (optional) would use a per-node image override if needed
      # ──────────────────────────────────────────────────────────────
      elasticsearch = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb   # data node default
        root_disk_size = 40
        data_disk_size = 300
        image_id       = var.ubuntu_2204_image_id   # override: Ubuntu 22.04 for this group
        security_group = [var.es_sg_id]
        floating       = false
        overrides = {
          "0" = { flavor_id = var.flavor_2cpu_4gb, root_disk_size = 20, data_disk_size = 0 }
          "1" = { flavor_id = var.flavor_2cpu_4gb, root_disk_size = 20, data_disk_size = 0 }
        }
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 8: Override image_id per node
      # worker-0 → Ubuntu 22.04 (new image, testing rollout)
      # worker-1, worker-2 → Ubuntu 20.04 (stable, from shared default)
      # ──────────────────────────────────────────────────────────────
      worker = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        security_group = [var.app_sg_id]
        floating       = false
        overrides = {
          "0" = { image_id = var.ubuntu_2204_image_id }   # canary node — Ubuntu 22.04
        }
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 9: Override root_disk_type_id + data_disk_type_id per node
      # cache-0 → NVMe root + NVMe data (high-perf primary)
      # cache-1, cache-2 → SSD root + SSD data (standard replicas)
      # ──────────────────────────────────────────────────────────────
      cache = {
        count             = 3
        flavor_id         = var.flavor_4cpu_8gb
        root_disk_size    = 20
        root_disk_type_id = var.ssd_disk_type_id    # group default: SSD
        data_disk_size    = 100
        data_disk_type_id = var.ssd_disk_type_id    # group default: SSD
        security_group    = [var.db_sg_id]
        floating          = false
        overrides = {
          "0" = {
            root_disk_type_id = var.nvme_disk_type_id   # cache-0 — NVMe root
            data_disk_type_id = var.nvme_disk_type_id   # cache-0 — NVMe data
          }
        }
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 5: Override floating IP for specific node only
      # bastion-0 → has public IP
      # bastion-1 → internal only
      # ──────────────────────────────────────────────────────────────
      bastion = {
        count          = 2
        flavor_id      = var.flavor_2cpu_2gb
        root_disk_size = 20
        security_group = [var.bastion_sg_id]
        floating       = false
        overrides = {
          "0" = { floating = true }
        }
      }
    }
  }
}

output "server_ids"          { value = module.vserver.server_ids }
output "server_ips"          { value = module.vserver.server_ips }
output "server_floating_ips" { value = module.vserver.server_floating_ips }
output "volume_ids"          { value = module.vserver.volume_ids }
