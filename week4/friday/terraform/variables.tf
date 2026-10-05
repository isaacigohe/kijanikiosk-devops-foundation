variable "image" {
  description = "Ubuntu image for the servers"
  type        = string
  default     = "ubuntu:22.04"
}

variable "ssh_key_name" {
  description = "Name of the SSH key in ~/.ssh"
  type        = string
  default     = "id_rsa"
}

variable "servers" {
  description = "Server definitions"
  type        = map(object({ cpus = number, memory = string }))
  default = {
    api      = { cpus = 1, memory = "1GiB" }
    payments = { cpus = 1, memory = "1GiB" }
    logs     = { cpus = 1, memory = "1GiB" }
  }
}
