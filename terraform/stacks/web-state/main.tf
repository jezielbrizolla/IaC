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

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "app" {
  name  = "lab11-app"
  image = docker_image.nginx.image_id
}

resource "docker_container" "orfao" {
  name  = "orfao"
  image = docker_image.nginx.image_id
  start = true
  must_run = true
  remove_volumes = true
  logs = false
  wait = false
  wait_timeout = 60

  ports {
    internal = 80
    external = 9090
  }
}
