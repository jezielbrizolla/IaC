# Capstone Lab 1 — a ponte Packer → Terraform

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `packer/ + terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h**

## Objetivo
Packer produz a imagem, Terraform consome. Pipeline de duas etapas ponta a ponta.

## Estrutura
```
12-capstone-ponte/
├── setup.sh
├── nginx.conf
├── docker.pkr.hcl
└── terraform/
    └── main.tf
```

## Arquivos Packer

`nginx.conf`:
```nginx
server {
    listen 80;
    server_name _;
    location / {
        return 200 'capstone v1\n';
        add_header Content-Type text/plain;
    }
}
```

`setup.sh`:
```bash
#!/usr/bin/env bash
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
```

`docker.pkr.hcl`:
```hcl
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

source "docker" "app" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    script = "setup.sh"
  }

  provisioner "file" {
    source      = "nginx.conf"
    destination = "/etc/nginx/sites-available/default"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
```

## Arquivo Terraform

`terraform/main.tf`:
```hcl
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
  filename = "${path.module}/../manifest.json"
}

locals {
  manifest = jsondecode(data.local_file.manifest.content)
  image_id = local.manifest.builds[length(local.manifest.builds) - 1].artifact_id
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
```

## Rodar
```powershell
cd labs\12-capstone-ponte
packer init .
packer build .
Get-Content manifest.json

cd terraform
terraform init
terraform apply -auto-approve
curl http://localhost:8080
```

## O teste que prova que funcionou
1. Com o container no ar, edite `nginx.conf` (troque `capstone v1` por `capstone v2`).
2. Volte para a pasta raiz do lab: `packer build .` de novo.
3. `cd terraform; terraform plan` — ele deve propor **substituir** o container,
   porque `local.image_id` mudou.
4. `terraform apply -auto-approve` e confirme com `curl http://localhost:8080`.

Esse ciclo — rebuild da imagem gera replace da instância — é literalmente o que
acontece com AMI + Auto Scaling Group na AWS. Você acabou de fazer local, em segundos.

## Quebre isto
```powershell
Remove-Item ..\manifest.json
terraform plan
```
Leia o erro: o `data "local_file"` falha antes de qualquer outra coisa ser
avaliada. Pense em como isso se comportaria dentro de um pipeline de CI que
roda Packer e Terraform em jobs separados — o que precisaria garantir essa
ordem? Restaure o manifest rodando `packer build .` de novo antes de seguir.

## Limpeza
```powershell
terraform destroy -auto-approve
```

## Critério de conclusão
Um comando de Packer + um de Terraform, e a mudança de conteúdo aparece no navegador.

## Notas
