terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}

provider "docker" {}

module "stack" {
  source = "../../modules/webapp"
  name   = "lab13-prod"
  port   = 8082
}

output "url" {
  value = module.stack.url
}
