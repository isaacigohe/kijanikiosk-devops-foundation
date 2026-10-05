output "ip" {
  description = "IP address of this server"
  value       = lxd_instance.vm.ipv4_address
}
