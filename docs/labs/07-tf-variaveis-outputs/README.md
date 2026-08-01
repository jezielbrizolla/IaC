# Terraform Lab 2 — variáveis, tipos e outputs

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h**

## Objetivo
Parametrizar a stack e expor informação de volta.

## Arquivos a criar

`variables.tf`:
```hcl
variable "container_name" {
  type    = string
  default = "lab07-web"
}

variable "external_port" {
  type = number

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "external_port precisa estar entre 1024 e 65535 (portas < 1024 exigem privilégio root)."
  }
}

variable "labels" {
  type = map(string)
  default = {
    ambiente = "lab"
  }
}
```

`main.tf`:
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

locals {
  full_name = "${var.container_name}-${var.labels["ambiente"]}"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = local.full_name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}
```

`outputs.tf`:
```hcl
output "url" {
  value = "http://localhost:${var.external_port}"
}

output "container_id" {
  value = docker_container.web.id
}
```

`terraform.tfvars`:
```hcl
external_port = 8081
```

## Rodar — teste as quatro formas de passar valor
```powershell
cd labs\07-tf-variaveis-outputs
terraform init

# 1. terraform.tfvars (aplicado automaticamente)
terraform apply -auto-approve
terraform output url

# 2. -var (sobrescreve o tfvars)
terraform apply -auto-approve -var="external_port=8082"

# 3. variável de ambiente
$env:TF_VAR_external_port = "8083"
terraform apply -auto-approve
Remove-Item Env:\TF_VAR_external_port

terraform destroy -auto-approve
```

## Quebre isto
```powershell
terraform apply -var="external_port=80"
```
Leia a mensagem do `validation`. Reescreva a `error_message` de um jeito que
**você mesmo** entenderia daqui a 6 meses, sem contexto.

## Entenda
`variable` = entrada do módulo, vem de fora. `locals` = valor derivado, calculado
dentro (como `local.full_name` aqui). Se você tem uma `variable` com `default`
que ninguém nunca sobrescreve, provavelmente era `locals`.

## Critério de conclusão
`terraform output url` imprime uma URL que abre no navegador, e você testou as
quatro formas de precedência (`-var` > `TF_VAR_*` > `terraform.tfvars` > `default`).

## Notas
