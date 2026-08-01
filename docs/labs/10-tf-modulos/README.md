# Terraform Lab 5 — módulos

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/modules/webapp/ + terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h**

## Objetivo
Empacotar e reutilizar.

## Estrutura a criar
```
10-tf-modulos/
├── main.tf
├── outputs.tf
└── modules/
    └── webapp/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Arquivos

`modules/webapp/variables.tf`:
```hcl
variable "name" {
  type = string
}

variable "port" {
  type = number
}
```

`modules/webapp/main.tf`:
```hcl
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_network" "net" {
  name = "${var.name}-net"
}

resource "docker_volume" "data" {
  name = "${var.name}-data"
}

resource "docker_container" "app" {
  name  = var.name
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.net.name
  }

  volumes {
    volume_name    = docker_volume.data.name
    container_path = "/usr/share/nginx/html"
  }

  ports {
    internal = 80
    external = var.port
  }
}
```

`modules/webapp/outputs.tf`:
```hcl
output "url" {
  value = "http://localhost:${var.port}"
}

output "container_id" {
  value = docker_container.app.id
}
```

`main.tf` (root):
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

module "app_a" {
  source = "./modules/webapp"
  name   = "lab10-app-a"
  port   = 8091
}

module "app_b" {
  source = "./modules/webapp"
  name   = "lab10-app-b"
  port   = 8092
}
```

`outputs.tf` (root):
```hcl
output "app_a_url" {
  value = module.app_a.url
}

output "app_b_url" {
  value = module.app_b.url
}
```

## Rodar
```powershell
cd labs\10-tf-modulos
terraform init
terraform apply -auto-approve
terraform output
curl http://localhost:8091
curl http://localhost:8092
terraform destroy -auto-approve
```

## Entenda `source`
Você usou o formato local acima. Conheça os outros dois (só leia a sintaxe,
não precisa aplicar):
- git: `source = "git::https://github.com/user/repo.git//modules/webapp?ref=v1.0.0"`
- registry: `source = "terraform-aws-modules/vpc/aws"` + `version = "~> 5.0"`

**Sempre pinar versão** em git (`?ref=`) e registry (`version =`).
Módulo sem pin é build não-reproduzível.

## Quebre isto
1. Adicione um `module "app_c" { source = "./modules/webapp" ... }` novo e rode
   `terraform plan` **sem** rodar `terraform init` antes. Leia o erro — módulo novo
   sempre exige `init`.
2. Agora adicione só um `resource` novo **dentro** de `modules/webapp/main.tf`
   (ex: outra `docker_volume`) e rode `terraform plan` sem `init`. Funciona —
   porque o módulo em si já estava inicializado; o que exige `init` é uma
   referência de módulo **nova**, não mudança de conteúdo de um módulo existente.

## Critério de conclusão
Duas apps rodando em portas diferentes, saindo do mesmo módulo, com outputs
expostos no root.

## Notas
