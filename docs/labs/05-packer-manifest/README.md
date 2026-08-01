# Packer Lab 5 — golden image + manifest

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `packer/templates/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h · a ponte**

## Objetivo
Fazer o Packer registrar **qual** imagem ele produziu, em formato legível por máquina.

## Arquivos a criar

`docker.pkr.hcl` (reaproveite o do Lab 3, adicione o post-processor):
```hcl
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "app_version" {
  type    = string
  default = "1.0"
}

source "docker" "app" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = ["echo build ${var.app_version}"]
  }

  post-processor "docker-tag" {
    repository = "meuapp"
    tag        = [var.app_version]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
```

## Rodar
```powershell
cd labs\05-packer-manifest
packer init .
packer build .
Get-Content manifest.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

Rode de novo com outra versão e veja o manifest **acumular**:
```powershell
packer build -var "app_version=2.0" .
Get-Content manifest.json | ConvertFrom-Json | Select-Object -ExpandProperty builds
```

## Depois do build
Abra `manifest.json` no editor. Entenda a estrutura: `builds[]` (array que cresce a
cada build), cada item com `name`, `artifact_id`, `custom_data`; e `last_run_uuid`
no topo, marcando o build mais recente.

## Por que isto importa
Este JSON é o contrato entre Packer e Terraform. No Bloco 3 (`12-capstone-ponte`) o
Terraform vai lê-lo com `jsondecode()` e subir exatamente esta imagem. Na AWS o
equivalente é o Terraform buscar a AMI com `data "aws_ami"` filtrando por uma tag
que o Packer escreveu.

## Quebre isto
Rode 3 builds seguidos (`-var "app_version=3.0"`, `4.0`, `5.0`) e depois tente
identificar "a imagem certa" olhando só o `manifest.json`. Você vai perceber que
precisa **decidir uma regra**: último item do array (`builds[length(builds)-1]`)?
Filtrar por `custom_data`? Casar com `last_run_uuid`?
Escreva a regra escolhida nas Notas — é o design da ponte, resolva aqui, não no capstone.

## Critério de conclusão
`manifest.json` existe, tem múltiplos builds, e você sabe qual campo/expressão usar
para pegar o ID da imagem mais recente.

## Notas
