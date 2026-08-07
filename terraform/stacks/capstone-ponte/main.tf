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

data "local_file" "manifest" {
  filename = "${path.module}/../../../packer/manifest.json"
}

locals {
  manifest = jsondecode(data.local_file.manifest.content)

  # Não confie em "o último item do array" — nada garante essa ordem se o
  # manifest for tocado por outro processo, ou se um build multi-source
  # (Lab 04) escrever várias entradas de uma vez. O campo last_run_uuid no
  # topo do manifest é feito exatamente para isso: aponta qual entrada é a
  # do build mais recente, sem depender de posição.
  last_build = [
    for b in local.manifest.builds : b
    if b.packer_run_uuid == local.manifest.last_run_uuid
  ][0]

  image_id = local.last_build.artifact_id
}

resource "docker_container" "app" {
  name  = "capstone-app"
  image = local.image_id

  ports {
    internal = 80
    external = 8080
  }

  command = ["nginx", "-g", "daemon off;"]
}

output "image_id" {
  value = local.image_id
}
