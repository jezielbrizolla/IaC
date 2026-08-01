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

source "docker" "alpine" {
  image  = "alpine:3.20"
  commit = true
}

build {
  sources = [
    "source.docker.ubuntu",
    "source.docker.alpine"
  ]

  provisioner "shell" {
    only = ["docker.ubuntu"]
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y curl"
    ]
  }

  provisioner "shell" {
    only = ["docker.alpine"]
    inline = [
      "apk add --no-cache curl"
    ]
  }

  post-processor "docker-tag" {
    repository = "multi-base"
    tags       = ["${source.name}"]
  }
}
