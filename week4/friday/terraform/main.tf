locals {
  # public key that goes on every server
  ssh_public_key = file(pathexpand("~/.ssh/${var.ssh_key_name}.pub"))
}

module "server" {
  for_each       = var.servers
  source         = "./modules/app_server"
  name           = "kijanikiosk-${each.key}"
  image          = var.image
  cpus           = each.value.cpus
  memory         = each.value.memory
  ssh_public_key = local.ssh_public_key
}
