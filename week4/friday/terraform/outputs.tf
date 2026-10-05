output "server_ips" {
  description = "IP address of each server"
  value       = { for k, m in module.server : k => m.ip }
}

output "ssh_commands" {
  description = "SSH command for each server"
  value       = { for k, m in module.server : k => "ssh -i ~/.ssh/${var.ssh_key_name} ubuntu@${m.ip}" }
}
