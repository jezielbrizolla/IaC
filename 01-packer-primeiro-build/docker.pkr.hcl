packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}


source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name    = "primeiro-build"
  sources = ["source.docker.ubuntu"]
}