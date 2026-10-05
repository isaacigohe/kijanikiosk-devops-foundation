resource "lxd_instance" "vm" {
  name  = var.name
  image = var.image
  type  = "container"

  limits = {
    cpu    = tostring(var.cpus)
    memory = var.memory
  }

  config = {
    "cloud-init.user-data" = templatefile("${path.module}/cloud-init.tpl", { ssh_key = var.ssh_public_key })
  }
}
