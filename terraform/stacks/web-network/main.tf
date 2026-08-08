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

resource "docker_network" "app_net" {
  name = "lab08-net"
}

resource "docker_volume" "app_data" {
  name = "lab08-data"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "lab08-web"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.app_net.name
  }

  volumes {
    volume_name    = docker_volume.app_data.name
    container_path = "/usr/share/nginx/html"
  }
}