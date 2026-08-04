# Terraform Lab 5 — módulos

**~1h**

## Objetivo
Empacotar e reutilizar.

## Onde o código mora
`terraform/modules/webapp/` (o módulo) + `terraform/stacks/web-modules/`
(o root que o chama duas vezes).

> **Conexão com o objetivo: este é *o* lab.** Um tenant = uma chamada de
> módulo com variáveis diferentes. Corrigir um guardrail no módulo corrige
> em todos os tenants de uma vez.

## Arquivos

`terraform/modules/webapp/variables.tf`:

```hcl
variable "name" {
  type = string
}

variable "port" {
  type = number
}
```

`terraform/modules/webapp/main.tf`:

```hcl
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

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

`terraform/modules/webapp/outputs.tf`:

```hcl
output "url" {
  value = "http://localhost:${var.port}"
}

output "container_id" {
  value = docker_container.app.id
}
```

`terraform/stacks/web-modules/main.tf` (o root que chama o módulo):

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
  source = "../../modules/webapp"
  name   = "lab10-app-a"
  port   = 8091
}

module "app_b" {
  source = "../../modules/webapp"
  name   = "lab10-app-b"
  port   = 8092
}
```

`terraform/stacks/web-modules/outputs.tf`:

```hcl
output "app_a_url" {
  value = module.app_a.url
}

output "app_b_url" {
  value = module.app_b.url
}
```

Repare em duas coisas de convenção:

- `source = "../../modules/webapp"` — caminho relativo **do stack até o
  módulo**, não do repo. `terraform/stacks/web-modules/` → sobe dois níveis
  → `terraform/modules/webapp/`.
- Só o **root** (`stacks/web-modules/main.tf`) declara `provider "docker" {}`
  de verdade. O módulo declara só `required_providers` — quem configura o
  provider é sempre quem chama, nunca o módulo. Ver "Quebre isto" nº 3.

## Rodar

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-modules init
terraform -chdir=terraform/stacks/web-modules apply -auto-approve
terraform -chdir=terraform/stacks/web-modules output
curl http://localhost:8091
curl http://localhost:8092
```

## Entenda `source`

Você usou o formato local acima. Conheça os outros dois (só leia a sintaxe,
não precisa aplicar):

- git: `source = "git::https://github.com/user/repo.git//modules/webapp?ref=v1.0.0"`
- registry: `source = "terraform-aws-modules/vpc/aws"` + `version = "~> 5.0"`

**Sempre pinar versão** em git (`?ref=`) e registry (`version =`).
Módulo sem pin é build não-reproduzível.

## Quebre isto

1. Adicione um `module "app_c" { source = "../../modules/webapp" ... }` novo
   e rode `terraform plan` **sem** rodar `terraform init` antes. Leia o erro
   — módulo novo sempre exige `init`.
2. Agora adicione só um `resource` novo **dentro** de
   `terraform/modules/webapp/main.tf` (ex: outra `docker_volume`) e rode
   `terraform plan` sem `init`. Funciona — porque o módulo em si já estava
   inicializado; o que exige `init` é uma referência de módulo **nova**, não
   mudança de conteúdo de um módulo existente.
3. Adicione `provider "docker" {}` vazio dentro de
   `terraform/modules/webapp/main.tf` e rode `terraform validate`. Você vai
   ver `Warning: Redundant empty provider block` — é sintaxe antiga
   (proxy provider configuration), deprecada. Quem configura provider é
   sempre quem **chama** o módulo, nunca o módulo em si; o módulo só declara
   do que precisa em `required_providers`. Remova antes de seguir.

## Critério de conclusão
Duas apps rodando em portas diferentes, saindo do mesmo módulo, com outputs
expostos no root.

## Limpeza

```powershell
terraform -chdir=terraform/stacks/web-modules destroy -auto-approve
```

## Notas

- **Módulo webapp criado e funcionando:** estrutura correta
  (`variables.tf`/`main.tf`/`outputs.tf`), chamado duas vezes do stack
  `web-modules` com `source = "../../modules/webapp"` — caminho relativo do
  stack até o módulo, não do repo.
- **As duas apps responderam:** `curl http://localhost:8091` e `:8092`
  retornaram 200, cada uma servida pelo seu próprio container/rede/volume,
  todos derivados do mesmo módulo com `name`/`port` diferentes.
- **Teste de quebra 1 confirmado:** `module "app_c"` novo sem `terraform
  init` → erro (`Module not installed`). Módulo novo exige init.
- **Teste de quebra 2 confirmado:** recurso novo (`docker_volume.logs`)
  dentro de um módulo **já** inicializado → `plan` funciona sem `init`. A
  distinção é referência de módulo nova vs conteúdo de módulo existente.
- **`provider "docker" {}` vazio dentro do módulo gerou warning real,
  reproduzido e confirmado:** `Warning: Redundant empty provider block` —
  proxy provider configuration, sintaxe deprecada desde versões antigas do
  Terraform. A prática correta: o módulo declara só `required_providers`
  (do que ele precisa), e quem configura o provider de verdade é sempre
  quem **chama** o módulo (o root/stack). Passar um provider explícito pra
  dentro de um módulo só é necessário em casos avançados (múltiplas contas
  do mesmo provider via `providers = {}`), não no caso comum.
