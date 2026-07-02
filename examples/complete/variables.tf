variable "project_id"           { type = string }
variable "ubuntu_2004_image_id" { type = string }
variable "ubuntu_2204_image_id" { type = string }
variable "network_id"           { type = string }
variable "private_subnet_id"    { type = string }
variable "nvme_disk_type_id"    { type = string }
variable "ssd_disk_type_id"     { type = string }
variable "server_group_id" {
  type    = string
  default = null
}
variable "flavor_8cpu_16gb" { type = string }
variable "flavor_4cpu_8gb"  { type = string }
variable "flavor_2cpu_4gb"  { type = string }
variable "flavor_2cpu_2gb"  { type = string }
variable "app_sg_id"        { type = string }
variable "db_sg_id"         { type = string }
variable "es_sg_id"         { type = string }
variable "bastion_sg_id"    { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "ssh_public_key" { type = string }
