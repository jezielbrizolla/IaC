packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "base_image" {
  type    = string
  default = "ubuntu:22.04"
}

variable "app_version" {
  type    = string
  default = "1.0"
}

locals {
  image_tag = "meuapp:${var.app_version}"
}

source "docker" "app" {
  image  = var.base_image
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = ["echo building ${local.image_tag}"]
  }

  post-processor "docker-tag" {
    repository = "meuapp"
    tags       = [var.app_version]
  }
}
