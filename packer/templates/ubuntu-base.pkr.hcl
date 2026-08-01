# Imagem base Ubuntu — sem provisionamento, só a base commitada.
# Piso das demais imagens e smoke test do toolchain.
#
# Paths relativos aqui dentro são resolvidos a partir de packer/,
# que é o diretório onde o Taskfile invoca o packer.

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
  name    = "ubuntu-base"
  sources = ["source.docker.ubuntu"]
}
