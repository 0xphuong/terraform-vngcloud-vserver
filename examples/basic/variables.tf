variable "project_id"        { type = string }
variable "image_id"           { type = string }
variable "network_id"         { type = string }
variable "subnet_id"          { type = string }
variable "disk_type_id"       { type = string }
variable "flavor_id"          { type = string }
variable "security_group_id"  { type = string }
variable "admin_password"     { type = string; sensitive = true }
variable "ssh_public_key"     { type = string }
