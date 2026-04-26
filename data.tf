data "cloudinit_config" "this" {
  gzip          = var.user_data_base64_encode
  base64_encode = var.user_data_base64_encode

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/init/cloud-config.tpl", {
      admin_user         = var.cloud_init.admin_user
      admin_password     = var.cloud_init.admin_password
      ssh_authorized_key = var.cloud_init.ssh_authorized_key
      ssh_port           = var.cloud_init.ssh_port
    })
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/init/custom-init.sh")
  }
}
