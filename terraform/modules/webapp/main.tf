terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}
 
provider "docker" {}
 
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}
 
resource "docker_network" "net" {
  name = "${var.name}-net"
}
 
resource "docker_volume" "data" {
  name = "${var.name}-data"
}

resource "docker_container" "app" {
  name  = var.name
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.net.name
  }
 
  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/usr/share/nginx/html"
  }
 
  ports {
    internal = 80
    external = var.port
  }
}
