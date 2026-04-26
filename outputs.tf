output "server_ids" {
  description = "Map of server key => server ID"
  value       = { for k, s in vngcloud_vserver_server.this : k => s.id }
}

output "server_ips" {
  description = "Map of server key => internal (fixed) IP"
  value       = { for k, s in vngcloud_vserver_server.this : k => s.internal_interfaces[0].fixed_ip }
}

output "server_floating_ips" {
  description = "Map of server key => floating IP (empty string if not assigned)"
  value       = { for k, s in vngcloud_vserver_server.this : k => s.internal_interfaces[0].floating_ip }
}

output "server_names" {
  description = "Map of server key => server name"
  value       = { for k, s in vngcloud_vserver_server.this : k => s.name }
}

output "volume_ids" {
  description = "Map of volume key => volume ID (only servers with data disk)"
  value       = { for k, v in vngcloud_vserver_volume.this : k => v.id }
}
