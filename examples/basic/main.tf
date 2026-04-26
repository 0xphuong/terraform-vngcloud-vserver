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
    encryption_volume = false
    image_id          = var.image_id
    network_id        = var.network_id
    subnet_id         = var.subnet_id
    root_disk_type_id = var.disk_type_id

    server_configs = {
      web = {
        count          = 1
        flavor_id      = var.flavor_id
        root_disk_size = 20
        security_group = [var.security_group_id]
        floating       = true
      }
    }
  }
}

output "server_ids"   { value = module.vserver.server_ids }
output "server_ips"   { value = module.vserver.server_ips }
