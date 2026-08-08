terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

variable "external_port" {
  type = number
}

locals {
  name = "lab13-${terraform.workspace}"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = local.name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}

output "url" {
  value = "http://localhost:${var.external_port}"
}
