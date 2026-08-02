variable "container_name" {
  type    = string
  default = "web"
}

variable "external_port" {
  type = number

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "A porta externa deve estar entre 1024 e 65535. Portas abaixo de 1024 sao reservadas para o sistema (exigem privilegio de root)."
  }
}

variable "labels" {
  type = map(string)
  default = {
    ambiente = "lab"
  }
}
