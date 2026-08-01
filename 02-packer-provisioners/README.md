# Packer Lab 2 — provisioners

**~1h · essencial**

## Objetivo
Instalar e configurar software dentro da imagem, em vez de só copiar uma base.

## Arquivos a criar

`nginx.conf`:
```nginx
server {
    listen 80;
    server_name _;
    location / {
        return 200 'packer provisioner lab ok\n';
        add_header Content-Type text/plain;
    }
}
```

`docker.pkr.hcl` — passo 1, `shell inline`:
```hcl
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
  name    = "provisioners"
  sources = ["source.docker.nginx"]

  provisioner "shell" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nginx"
    ]
  }

  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/sites-available/default"
  }
}
```

## Rodar
```powershell
cd labs\02-packer-provisioners
packer init .
packer build .
# pega o ID da imagem que apareceu no output (ex: sha256:xxxx) ou:
docker images --filter "dangling=false" | Select-Object -First 5

docker run -d --name nginx-lab -p 8080:80 <IMAGE_ID_OU_TAG> nginx -g "daemon off;"
curl http://localhost:8080
docker rm -f nginx-lab
```

## Passo 2 — migrar para script externo
Crie `setup.sh`:
```bash
#!/usr/bin/env bash
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
```

Troque o `provisioner "shell"` por:
```hcl
provisioner "shell" {
  script = "setup.sh"
}
```
Rode `packer build .` de novo e confirme que o resultado é o mesmo.

## Quebre isto
Inverta a ordem: coloque o `provisioner "file"` **antes** do `provisioner "shell"`
que instala o nginx (o diretório `/etc/nginx/sites-available/` ainda não existe
nesse ponto do build). Rode `packer build .` e leia o erro.
Provisioners rodam **na ordem declarada** — não há resolução automática de
dependência como no Terraform. Depois, devolva à ordem correta.

## Critério de conclusão
`curl http://localhost:8080` retorna `packer provisioner lab ok`.

## Entenda
Este é o motivo do Packer existir: instalar no **build time**, uma vez, em vez de
a cada boot. Um `provisioner` do Terraform fazendo esse trabalho é o anti-padrão clássico.

## Notas
