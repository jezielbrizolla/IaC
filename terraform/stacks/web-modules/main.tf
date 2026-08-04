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

module "app_a" {
  source = "../../modules/webapp"
  name   = "lab10-app-a"
  port   = 8091
}

module "app_b" {
  source = "../../modules/webapp"
  name   = "lab10-app-b"
  port   = 8092
}
