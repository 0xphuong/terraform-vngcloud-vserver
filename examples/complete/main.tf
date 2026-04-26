module "vserver" {
  source = "github.com/binhphuongit/terraform-vngcloud-vserver?ref=v1.0.0"

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
      app = {
        count          = 2
        flavor_id      = var.flavor_4cpu_8gb
        root_disk_size = 40
        data_disk_size = 100
        security_group = [var.app_sg_id]
        floating       = false
      }
      mongodb = {
        count          = 1
        flavor_id      = var.flavor_2cpu_4gb
        root_disk_size = 20
        data_disk_size = 200
        security_group = [var.db_sg_id]
        floating       = false
      }
      bastion = {
        count          = 1
        flavor_id      = var.flavor_2cpu_2gb
        root_disk_size = 20
        security_group = [var.bastion_sg_id]
        floating       = true
      }
    }
  }
}

output "server_ids"          { value = module.vserver.server_ids }
output "server_ips"          { value = module.vserver.server_ips }
output "server_floating_ips" { value = module.vserver.server_floating_ips }
output "volume_ids"          { value = module.vserver.volume_ids }
