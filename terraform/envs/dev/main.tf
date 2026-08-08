terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}

provider "docker" {}

module "stack" {
  source = "../../modules/webapp"
  name   = "lab13-dev"
  port   = 8081
}

output "url" {
  value = module.stack.url
}
