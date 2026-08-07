packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

source "docker" "app" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    script = "scripts/install-nginx.sh"
  }

  provisioner "file" {
    source      = "files/capstone/default.conf"
    destination = "/etc/nginx/sites-available/default"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
