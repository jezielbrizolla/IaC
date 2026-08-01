packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "app_version" {
  type    = string
  default = "1.0"
}

source "docker" "app" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = ["echo build ${var.app_version}"]
  }

  post-processor "docker-tag" {
    repository = "golden"
    tags       = [var.app_version]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
