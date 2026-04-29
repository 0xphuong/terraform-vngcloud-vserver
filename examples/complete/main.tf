module "vserver" {
  source = "github.com/0xphuong/terraform-vngcloud-vserver?ref=v1.1.0"

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
    image_id          = var.ubuntu_2004_image_id
    network_id        = var.network_id
    subnet_id         = var.private_subnet_id
    root_disk_type_id = var.nvme_disk_type_id
    data_disk_type_id = var.nvme_disk_type_id
    server_group_id   = var.server_group_id

    server_configs = {

      # ──────────────────────────────────────────────────────────────
      # Use case 1: All nodes identical (no overrides)
      # app-0, app-1, app-2 → same flavor + disk
      # ──────────────────────────────────────────────────────────────
      app = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 100
        security_group = [var.app_sg_id]
        floating       = false
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 2: Master/worker pattern
      # app-0 → master (larger flavor + disk)
      # app-1, app-2 → worker (default)
      # ──────────────────────────────────────────────────────────────
      # app = {
      #   count          = 3
      #   flavor_id      = var.flavor_4cpu_8gb   # worker default
      #   root_disk_size = 40
      #   data_disk_size = 100
      #   security_group = [var.app_sg_id]
      #   overrides = {
      #     "0" = { flavor_id = var.flavor_8cpu_16gb, root_disk_size = 80 }
      #   }
      # }

      # ──────────────────────────────────────────────────────────────
      # Use case 3: Override only 1 field (primary node bigger disk)
      # mongodb-0 → 500 GB data disk (primary)
      # mongodb-1, mongodb-2 → 200 GB data disk (secondary)
      # ──────────────────────────────────────────────────────────────
      mongodb = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 200
        security_group = [var.db_sg_id]
        floating       = false
        overrides = {
          "0" = { data_disk_size = 500 }
        }
      }

      # ──────────────────────────────────────────────────────────────
      # Use case 4: Multiple overrides, fully different configs
      # es-0, es-1 → master node (no data disk, smaller flavor)
      # es-2       → data node (default, large disk)
      # ──────────────────────────────────────────────────────────────
      elasticsearch = {
        count          = 3
        flavor_id      = var.flavor_4cpu_8gb   # data node default
        root_disk_size = 40
        data_disk_size = 300
        security_group = [var.es_sg_id]
        floating       = false
        overrides = {
          "0" = { flavor_id = var.flavor_2cpu_4gb, root_disk_size = 20, data_disk_size = 0 }
          "1" = { flavor_id = var.flavor_2cpu_4gb, root_disk_size = 20, data_disk_size = 0 }
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
