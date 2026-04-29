variable "project_id" {
  description = "VNG Cloud project ID"
  type        = string
}

variable "user_data_base64_encode" {
  description = "Encode user_data as base64 and gzip (required for some images)"
  type        = bool
  default     = false
}

variable "cloud_init" {
  description = "Cloud-init configuration for server bootstrapping"
  type = object({
    admin_user         = optional(string, "stackops")
    admin_password     = string
    ssh_authorized_key = string
    ssh_port           = optional(number, 234)
  })
  sensitive = true

  validation {
    condition     = length(var.cloud_init.admin_password) >= 8
    error_message = "admin_password must be at least 8 characters."
  }
  validation {
    condition     = var.cloud_init.ssh_port > 0 && var.cloud_init.ssh_port <= 65535
    error_message = "ssh_port must be between 1 and 65535."
  }
}

variable "servers" {
  description = "Shared server parameters and per-server configurations"
  type = object({
    encryption_volume = bool
    image_id          = string
    network_id        = string
    subnet_id         = string
    root_disk_type_id = string
    data_disk_type_id = optional(string, null)
    server_group_id   = optional(string, null)
    server_configs = map(object({
      count          = number
      flavor_id      = string
      root_disk_size = number
      security_group = list(string)
      floating       = optional(bool, false)
      data_disk_size = optional(number, 0)
      overrides      = optional(map(object({
        flavor_id      = optional(string)
        root_disk_size = optional(number)
        security_group = optional(list(string))
        floating       = optional(bool)
        data_disk_size = optional(number)
      })), {})
    }))
  })

  validation {
    condition     = alltrue([for k, v in var.servers.server_configs : v.count > 0])
    error_message = "Each server_config must have count >= 1."
  }
  validation {
    condition     = alltrue([for k, v in var.servers.server_configs : v.root_disk_size >= 20])
    error_message = "root_disk_size must be at least 20 GB."
  }
}
