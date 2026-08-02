# Capstone Lab 2 — dois ambientes

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/envs/{dev,prod}/ + terraform/modules/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h**

## Objetivo
Rodar a mesma stack em `dev` e `prod`, e entender os limites de workspace.

## Parte 1 — workspaces

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

variable "external_port" {
  type = number
}

locals {
  name = "lab13-${terraform.workspace}"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = local.name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}

output "url" {
  value = "http://localhost:${var.external_port}"
}
```

`dev.tfvars`:
```hcl
external_port = 8081
```

`prod.tfvars`:
```hcl
external_port = 8082
```

```powershell
cd labs\13-capstone-ambientes
terraform init
terraform workspace new dev
terraform workspace new prod
terraform workspace list

terraform workspace select dev
terraform apply -auto-approve -var-file="dev.tfvars"

terraform workspace select prod
terraform apply -auto-approve -var-file="prod.tfvars"

Get-ChildItem terraform.tfstate.d
```
Confirme que existe um state por workspace, e que os dois containers
(`lab13-dev` e `lab13-prod`) estão rodando ao mesmo tempo.

## Parte 2 — a armadilha (o ponto do lab)
Workspaces compartilham:
- o **mesmo backend** (mesma conta/bucket)
- as **mesmas credenciais**
- o **mesmo código**, sem chance de divergir

Ou seja: um `terraform workspace select` errado aplica em prod achando que era
dev, e não existe barreira de permissão entre os dois. Reproduza o risco:
```powershell
terraform workspace select prod
terraform apply -auto-approve -var-file="dev.tfvars"   # "esqueceu" de trocar o tfvars
```
Você acabou de aplicar a config de dev no workspace de prod sem nenhum aviso.
Desfaça: `terraform apply -auto-approve -var-file="prod.tfvars"`.

Por isso o padrão de mercado para prod/non-prod **não** é workspace, e sim
**diretórios + backends + credenciais separados**, com o código comum vivendo
em módulos. Workspace é ótimo para: ambientes efêmeros de feature branch,
testes, sandbox pessoal.

## Parte 3 — refaça do jeito certo

```text
13-capstone-ambientes/
├── modules/
│   └── stack/
│       ├── main.tf        # o resource docker_container, parametrizado
│       ├── variables.tf
│       └── outputs.tf
└── envs/
    ├── dev/
    │   ├── main.tf        # module "stack" { source = "../../modules/stack" ... }
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        └── terraform.tfvars
```

`modules/stack/variables.tf`:
```hcl
variable "name" {
  type = string
}
variable "external_port" {
  type = number
}
```

`modules/stack/main.tf`:
```hcl
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = var.name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}
```

`modules/stack/outputs.tf`:
```hcl
output "url" {
  value = "http://localhost:${var.external_port}"
}
```

`envs/dev/main.tf`:
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}

provider "docker" {}

module "stack" {
  source        = "../../modules/stack"
  name          = "lab13-dev"
  external_port = 8081
}

output "url" {
  value = module.stack.url
}
```
`envs/prod/main.tf` é o mesmo trocando `name = "lab13-prod"` e `external_port = 8082`.

```powershell
terraform workspace select default
cd envs\dev
terraform init
terraform apply -auto-approve

cd ..\prod
terraform init
terraform apply -auto-approve
```
Note: cada pasta tem seu **próprio** `.terraform/` e (num cenário real) seu
próprio backend — a chance de aplicar dev em prod por engano fica estruturalmente
mais difícil, não só uma questão de atenção.

## Anote
Essa conclusão reaparece no **Track 4 do plano de ramp-up multi-cloud** (state por
tenant). Escreva agora, com suas palavras, por que você separaria por diretório —
é resposta de entrevista.

## Limpeza
```powershell
cd envs\dev; terraform destroy -auto-approve
cd ..\prod; terraform destroy -auto-approve
cd ..\..
terraform workspace select dev; terraform destroy -auto-approve -var-file="dev.tfvars"
terraform workspace select prod; terraform destroy -auto-approve -var-file="prod.tfvars"
terraform workspace select default
terraform workspace delete dev
terraform workspace delete prod
```

## Critério de conclusão
Você fez das duas formas e sabe defender a segunda numa conversa técnica.

## Notas
