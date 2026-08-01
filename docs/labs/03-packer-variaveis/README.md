# Packer Lab 3 — variáveis e locals

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `packer/templates/ + packer/vars/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h**

## Objetivo
Parametrizar a imagem base e a versão do app.

## Arquivos a criar

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

variable "base_image" {
  type    = string
  default = "ubuntu:22.04"
}

variable "app_version" {
  type    = string
  default = "1.0"
}

locals {
  image_tag = "meuapp:${var.app_version}"
}

source "docker" "app" {
  image  = var.base_image
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = ["echo building ${local.image_tag}"]
  }

  post-processor "docker-tag" {
    repository = "meuapp"
    tag        = [var.app_version]
  }
}
```

`variables.pkrvars.hcl`:
```hcl
app_version = "1.1"
```

## Rodar — teste as quatro formas de passar valor
```powershell
cd labs\03-packer-variaveis
packer init .
packer fmt .
packer validate .

# 1. default (app_version = 1.0)
packer build .

# 2. -var
packer build -var "app_version=2.0" .

# 3. -var-file
packer build -var-file="variables.pkrvars.hcl" .

# 4. env var PKR_VAR_*
$env:PKR_VAR_app_version = "3.0"
packer build .
Remove-Item Env:\PKR_VAR_app_version

packer inspect .
docker images meuapp
```
Confirme no `docker images` que existem tags `1.0`, `2.0`, `1.1` e `3.0`.

## Quebre isto
1. Declare uma nova `variable "must_have" { type = string }` **sem** `default` e sem
   passar valor em lugar nenhum. Rode `packer build .` e leia o erro de validação.
2. Marque-a `sensitive = true`, passe um valor e veja como ela some do output do build
   (mas não do `packer inspect .` — objetivo é aprender a diferença).
3. Remova a variável de teste antes de seguir.

## Critério de conclusão
`packer fmt .` e `packer validate .` limpos, e o mesmo template produz 4 imagens
diferentes só mudando a forma de passar `app_version`.

## Notas
