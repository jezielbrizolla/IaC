# Imagem Ubuntu + nginx, servindo uma config própria.
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

source "docker" "nginx" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name    = "ubuntu-nginx"
  sources = ["source.docker.nginx"]

  # Instalação via script externo em vez de inline: o mesmo script é
  # reaproveitado por outras imagens (ex: a golden image do bloco 4).
  provisioner "shell" {
    script = "scripts/install-nginx.sh"
  }

  # Só depois do nginx instalado é que /etc/nginx/... existe.
  # Provisioners rodam na ordem declarada — não há grafo de dependência aqui.
  provisioner "file" {
    source      = "files/nginx/default.conf"
    destination = "/etc/nginx/sites-available/default"
  }
}
