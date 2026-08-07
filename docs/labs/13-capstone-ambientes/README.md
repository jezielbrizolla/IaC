# Capstone Lab 2 — dois ambientes

**~1h**

## Objetivo
Rodar a mesma stack em `dev` e `prod`, e entender os limites de workspace.

> **Conexão com o objetivo:** isolamento por diretório/backend é o padrão que
> escala para isolamento por tenant.

## Onde o código mora

- **Parte 1:** `terraform/stacks/capstone-ambientes-ws/` — stack novo,
  usa `terraform workspace`.
- **Parte 3:** `terraform/envs/dev/` + `terraform/envs/prod/`, os dois
  chamando o **mesmo módulo `terraform/modules/webapp/`** já criado no
  Lab 10 — nada novo pra escrever ali, só duas chamadas com parâmetros
  diferentes.

## Parte 1 — workspaces

`terraform/stacks/capstone-ambientes-ws/main.tf`:

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

`terraform/stacks/capstone-ambientes-ws/dev.tfvars`:

```hcl
external_port = 8081
```

`terraform/stacks/capstone-ambientes-ws/prod.tfvars`:

```hcl
external_port = 8082
```

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/capstone-ambientes-ws init
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace new dev
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace new prod
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace list

terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select dev
terraform -chdir=terraform/stacks/capstone-ambientes-ws apply -auto-approve -var-file="dev.tfvars"

terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select prod
terraform -chdir=terraform/stacks/capstone-ambientes-ws apply -auto-approve -var-file="prod.tfvars"

Get-ChildItem terraform\stacks\capstone-ambientes-ws\terraform.tfstate.d
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
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select prod
terraform -chdir=terraform/stacks/capstone-ambientes-ws apply -auto-approve -var-file="dev.tfvars"
```

Você acabou de aplicar a config de dev no workspace de prod sem nenhum aviso.
Desfaça:

```powershell
terraform -chdir=terraform/stacks/capstone-ambientes-ws apply -auto-approve -var-file="prod.tfvars"
```

Por isso o padrão de mercado para prod/non-prod **não** é workspace, e sim
**diretórios + backends + credenciais separados**, com o código comum vivendo
em módulos. Workspace é ótimo para: ambientes efêmeros de feature branch,
testes, sandbox pessoal.

## Parte 3 — refaça do jeito certo

`terraform/envs/dev/main.tf`:

```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = { source = "kreuzwerker/docker", version = "~> 3.0" }
  }
}

provider "docker" {}

module "stack" {
  source = "../../modules/webapp"
  name   = "lab13-dev"
  port   = 8081
}

output "url" {
  value = module.stack.url
}
```

`terraform/envs/prod/main.tf` é o mesmo, trocando `name = "lab13-prod"` e
`port = 8082`.

```powershell
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select default

terraform -chdir=terraform/envs/dev init
terraform -chdir=terraform/envs/dev apply -auto-approve

terraform -chdir=terraform/envs/prod init
terraform -chdir=terraform/envs/prod apply -auto-approve
```

Note: cada pasta tem seu **próprio** `.terraform/` e (num cenário real) seu
próprio backend — a chance de aplicar dev em prod por engano fica estruturalmente
mais difícil, não só uma questão de atenção. E o módulo é o **mesmo** do
Lab 10 — a prova de que "empacotar uma vez, chamar várias" funciona tanto
pra múltiplas instâncias no mesmo ambiente (Lab 10) quanto pra ambientes
inteiros diferentes (aqui).

## Anote
Essa conclusão reaparece no próximo track (provisionamento multi-cloud — ver
[`docs/PROXIMO-TRACK.md`](../PROXIMO-TRACK.md), pergunta em aberto sobre
isolamento de state por tenant×provider). Escreva agora, com suas palavras,
por que você separaria por diretório — é resposta de entrevista.

## Critério de conclusão
Você fez das duas formas e sabe defender a segunda numa conversa técnica.

## Limpeza

```powershell
terraform -chdir=terraform/envs/dev destroy -auto-approve
terraform -chdir=terraform/envs/prod destroy -auto-approve

terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select dev
terraform -chdir=terraform/stacks/capstone-ambientes-ws destroy -auto-approve -var-file="dev.tfvars"
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select prod
terraform -chdir=terraform/stacks/capstone-ambientes-ws destroy -auto-approve -var-file="prod.tfvars"
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select default
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace delete dev
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace delete prod
```

## Notas
