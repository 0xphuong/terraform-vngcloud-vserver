locals {
  expanded_servers = flatten([
    for server_name, config in var.servers.server_configs : [
      for i in range(config.count) : {
        key  = "${server_name}-${i}"
        name = "${server_name}-${i}"

        flavor_id = try(
          config.overrides[tostring(i)].flavor_id != null ? config.overrides[tostring(i)].flavor_id : config.flavor_id,
          config.flavor_id
        )
        root_disk_size = try(
          config.overrides[tostring(i)].root_disk_size != null ? config.overrides[tostring(i)].root_disk_size : config.root_disk_size,
          config.root_disk_size
        )
        security_group = try(
          config.overrides[tostring(i)].security_group != null ? config.overrides[tostring(i)].security_group : config.security_group,
          config.security_group
        )
        floating = try(
          config.overrides[tostring(i)].floating != null ? config.overrides[tostring(i)].floating : config.floating,
          config.floating
        )
        data_disk_size = try(
          config.overrides[tostring(i)].data_disk_size != null ? config.overrides[tostring(i)].data_disk_size : config.data_disk_size,
          config.data_disk_size
        )
        zone_id = try(
          config.overrides[tostring(i)].zone_id != null ? config.overrides[tostring(i)].zone_id : config.zone_id,
          config.zone_id
        )
      }
    ]
  ])

  server_map = { for s in local.expanded_servers : s.key => s }

  volume_map = {
    for s in local.expanded_servers : s.key => s
    if s.data_disk_size != 0
  }
}

resource "vngcloud_vserver_server" "this" {
  for_each = local.server_map

  project_id              = var.project_id
  name                    = each.value.name
  encryption_volume       = var.servers.encryption_volume
  flavor_id               = each.value.flavor_id
  image_id                = var.servers.image_id
  network_id              = var.servers.network_id
  root_disk_size          = each.value.root_disk_size
  root_disk_type_id       = var.servers.root_disk_type_id
  security_group          = each.value.security_group
  subnet_id               = var.servers.subnet_id
  attach_floating         = each.value.floating
  action                  = "start"
  expire_password         = false
  server_group_id         = var.servers.server_group_id
  user_data_base64_encode = var.user_data_base64_encode
  user_data               = data.cloudinit_config.this.rendered

  # Optional
  zone_id = each.value.zone_id != null ? each.value.zone_id : null

  lifecycle {
    create_before_destroy = true
  }
}

resource "vngcloud_vserver_volume" "this" {
  for_each = local.volume_map

  project_id     = var.project_id
  name           = "data-${each.value.name}"
  size           = each.value.data_disk_size
  volume_type_id = var.servers.data_disk_type_id

  lifecycle {
    create_before_destroy = true
  }
}

resource "vngcloud_vserver_volume_attach" "this" {
  for_each = local.volume_map

  project_id = var.project_id
  volume_id  = vngcloud_vserver_volume.this[each.key].id
  server_id  = vngcloud_vserver_server.this[each.key].id
}
