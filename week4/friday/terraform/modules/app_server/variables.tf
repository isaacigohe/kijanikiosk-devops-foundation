variable "name" {
  description = "Server name"
  type        = string
}

variable "image" {
  description = "Ubuntu image"
  type        = string
}

variable "cpus" {
  description = "Number of CPUs"
  type        = number
}

variable "memory" {
  description = "Memory limit, e.g. 1GiB"
  type        = string
}

variable "ssh_public_key" {
  description = "Public key text added to the server"
  type        = string
}
