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

> **Destrua a Parte 1/2 antes de continuar.** Os containers `lab13-dev` e
> `lab13-prod` da Parte 1 usam os **mesmos nomes literais** que a Parte 3
> vai criar — e o Docker é um daemon único e compartilhado, sem noção de
> "isso veio de um state diferente". Se não destruir agora, o `apply` da
> Parte 3 falha com `Conflict: the container name ... is already in use`,
> porque o nome já está ocupado por um recurso de um state completamente
> diferente:
>
> ```powershell
> terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select dev
> terraform -chdir=terraform/stacks/capstone-ambientes-ws destroy -auto-approve -var-file="dev.tfvars"
> terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select prod
> terraform -chdir=terraform/stacks/capstone-ambientes-ws destroy -auto-approve -var-file="prod.tfvars"
> terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select default
> ```

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

A Parte 1/2 já foi destruída antes da Parte 3 (passo acima) — só sobra
remover os workspaces vazios e a Parte 3:

```powershell
terraform -chdir=terraform/envs/dev destroy -auto-approve
terraform -chdir=terraform/envs/prod destroy -auto-approve

terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace delete dev
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace delete prod
```

## Notas

- **Parte 1 confirmada com evidência, não só pelo output:** `lab13-dev`
  (8081) e `lab13-prod` (8082) rodando ao mesmo tempo, cada workspace com
  seu próprio state em `terraform.tfstate.d/` (2 recursos gerenciados cada).
- **Parte 2 foi mais dramática que o roteiro previa.** Aplicar `dev.tfvars`
  no workspace `prod` não só "confundiu a config" — mudou a porta
  (`external`), que força `replace` do container. O Terraform destruiu o
  `lab13-prod` antigo e falhou ao criar o novo: a porta 8081 já estava
  ocupada pelo `lab13-dev` de verdade, rodando fora dessa mesma operação.
  Resultado: **prod ficou fora do ar** (`docker ps` mostrou `lab13-prod` em
  `Created`, não `Up`) até o `apply -var-file="prod.tfvars"` corrigir e
  religar na porta certa. Não foi só risco teórico — foi incidente real,
  ainda que em Docker local.
- **Achado real de fluxo do lab, corrigido no README:** a Parte 3 colidiu
  de cara com a Parte 1 — `Error: Conflict. The container name "/lab13-dev"
  is already in use`. Os nomes são literais (`lab13-dev`, `lab13-prod`) nos
  dois exercícios, e o Docker não faz ideia de que vêm de states Terraform
  diferentes. A limpeza da Parte 1/2, que só existia no final do README,
  precisa acontecer **antes** da Parte 3 — corrigido, com o passo de
  destroy movido pra logo antes dos arquivos de `envs/`.
- **Parte 3 confirmada:** depois da limpeza, os dois `apply` (`envs/dev` e
  `envs/prod`) criaram os 4 recursos cada (via módulo `webapp` do Lab 10) e
  os dois containers subiram ao mesmo tempo, sem qualquer conflito de nome
  — a estrutura por diretório realmente elimina a colisão que workspace não
  evita.
