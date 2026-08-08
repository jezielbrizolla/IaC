# Terraform Lab 5 — módulos

**~1h**

## Objetivo
Empacotar e reutilizar.

## Teoria

**Módulo é a unidade reutilizável do Terraform — o equivalente a uma função.**
Você tem um conjunto de recursos que sempre andam juntos (container + rede +
volume). Em vez de copiar esse bloco toda vez que precisar de mais uma
instância, você empacota uma vez e **chama** com parâmetros diferentes.

A analogia com função é literal:

| Função | Módulo |
|---|---|
| Parâmetros | `variable` |
| Corpo | os `resource` dentro do módulo |
| Retorno | `output` |
| Chamada | bloco `module "nome" { ... }` |

**O ganho real não é escrever menos — é corrigir em um lugar só.** Se você
descobre que faltou um guardrail (uma política de restart, um limite de
memória, uma tag obrigatória), corrige **no módulo** e todos os chamadores
herdam. Com blocos copiados, você teria que caçar cada cópia — e esquecer uma
é o normal.

> **Conexão com o objetivo: este é *o* lab.** Um tenant = uma chamada de
> módulo com variáveis diferentes. Corrigir um guardrail no módulo corrige
> em todos os tenants de uma vez. Todo o resto do Track 0 aponta pra cá.

**Quem configura o provider é sempre quem chama.** O módulo declara do que
*precisa* (`required_providers`), mas não configura *como* conectar
(`provider "docker" {}`). Isso fica no root. A razão: um módulo não deve
decidir em qual conta, região ou host ele roda — quem chama decide. Um
`provider {}` vazio dentro do módulo é sintaxe antiga e o Terraform avisa
(ver "Quebre isto" nº 3).

**`source` — de onde vem o módulo.** Três formatos:

| Formato | Exemplo | Quando |
|---|---|---|
| Local | `"../../modules/webapp"` | módulo no mesmo repo |
| Git | `"git::https://…//modules/webapp?ref=v1.0.0"` | compartilhado entre repos |
| Registry | `"terraform-aws-modules/vpc/aws"` + `version` | módulo publicado |

**Sempre pinar versão** em git (`?ref=`) e registry (`version =`). Módulo sem
pin é build não-reproduzível: o que funcionou hoje pode quebrar amanhã porque
alguém mexeu no módulo remoto.

**`terraform init` e módulos:** adicionar uma *referência de módulo nova* exige
`init` de novo (o Terraform precisa copiar o módulo pro `.terraform/`). Mas
mudar o *conteúdo* de um módulo já inicializado, não — é exatamente a
distinção que o "Quebre isto" nº 1 e nº 2 exploram.

## O que vamos criar

`terraform/modules/webapp/` (o módulo, 3 arquivos) +
`terraform/stacks/web-modules/` (o root que o chama duas vezes, 2 arquivos).

Repare no `source = "../../modules/webapp"` — caminho relativo **do stack até
o módulo**, não do repo. `terraform/stacks/web-modules/` → sobe dois níveis →
`terraform/modules/webapp/`.

## Passo 1 — criar o módulo e o stack

Rode da raiz `labs/`:

```powershell
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). `Set-Content -Encoding UTF8` no PowerShell 5.1 grava
# UTF-8 *com BOM*, e o BOM faz o `terraform fmt -check` do CI falhar.
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

# --- O MÓDULO (a unidade reutilizável) ---

Write-RepoFile "terraform/modules/webapp/variables.tf" @'
variable "name" {
  type = string
}

variable "port" {
  type = number
}
'@

Write-RepoFile "terraform/modules/webapp/main.tf" @'
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
'@

Write-RepoFile "terraform/modules/webapp/outputs.tf" @'
output "url" {
  value = "http://localhost:${var.port}"
}

output "container_id" {
  value = docker_container.app.id
}
'@

# --- O ROOT (quem chama o módulo duas vezes) ---

Write-RepoFile "terraform/stacks/web-modules/main.tf" @'
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
'@

Write-RepoFile "terraform/stacks/web-modules/outputs.tf" @'
output "app_a_url" {
  value = module.app_a.url
}

output "app_b_url" {
  value = module.app_b.url
}
'@
```

## Passo 2 — rodar

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-modules init
terraform -chdir=terraform/stacks/web-modules apply -auto-approve
terraform -chdir=terraform/stacks/web-modules output
curl http://localhost:8091
curl http://localhost:8092
```

Duas aplicações no ar, em portas diferentes, cada uma com sua própria rede e
volume — **saindo do mesmo módulo**. O `output` do root vem dos `output` do
módulo, repassados.

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
