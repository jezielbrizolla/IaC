# Capstone Lab 2 — dois ambientes

**~1h**

## Objetivo
Rodar a mesma stack em `dev` e `prod`, e entender os limites de workspace.

## Teoria

**A pergunta:** você tem a mesma stack rodando em `dev` e `prod`. Como separa?

O Terraform oferece **workspaces** — e é uma armadilha, porque a ferramenta
existe, funciona, e é a resposta errada para este caso específico. Este lab
existe pra você sentir por quê antes de escolher errado num projeto real.

**O que workspace faz.** Um `terraform workspace` cria um **state separado**
dentro do mesmo diretório. `terraform.workspace` vira uma variável que você
pode usar no código (`"lab13-${terraform.workspace}"`). Você alterna com
`workspace select`.

Parece isolamento. Mas veja o que continua **compartilhado**:

| Compartilhado entre workspaces | Consequência |
|---|---|
| O mesmo **backend** | mesmo bucket/conta guardando os states |
| As mesmas **credenciais** | quem aplica em dev tem acesso a prod |
| O **mesmo código**, sem chance de divergir | não dá pra testar mudança em dev antes de prod |
| O mesmo diretório | um `select` errado e você aplicou no lugar errado |

**A falha é de desenho, não de atenção.** Não existe barreira nenhuma entre
`dev` e `prod` — só o seu cuidado em rodar `workspace select` certo. E como o
comando não avisa nada, você descobre o erro depois.

**O padrão de mercado: diretório por ambiente.** Cada ambiente é uma pasta,
com seu próprio backend, suas próprias credenciais, seu próprio
`.terraform/`. O código comum vive num **módulo** (Lab 10), chamado por cada
ambiente com parâmetros diferentes.

```text
modules/webapp/          ← o código, uma vez
envs/dev/main.tf         ← chama o módulo com valores de dev
envs/prod/main.tf        ← chama o módulo com valores de prod
```

A diferença essencial: agora aplicar em prod exige **estar no diretório de
prod**, com as credenciais de prod. A separação é estrutural.

**Quando workspace é a ferramenta certa**, então? Para ambientes **efêmeros e
equivalentes**: um por feature branch, um por desenvolvedor, sandbox de teste.
Casos em que não há diferença de criticidade nem de credencial — só de
instância.

> **Conexão com o objetivo:** isolamento por diretório/backend é o padrão que
> escala para isolamento por tenant. A mesma pergunta vai reaparecer com N
> tenants: state compartilhado ou separado? A resposta é a mesma, pelas
> mesmas razões.

## O que vamos criar

- **Passos 1–3 (o jeito problemático):**
  `terraform/stacks/capstone-ambientes-ws/` — stack novo usando
  `terraform workspace`.
- **Passo 4 (o jeito certo):** `terraform/envs/dev/` + `terraform/envs/prod/`,
  os dois chamando o **mesmo módulo `terraform/modules/webapp/`** já criado no
  Lab 10 — nada novo pra escrever ali, só duas chamadas com parâmetros
  diferentes.

## Passo 1 — criar o stack de workspaces

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

Write-RepoFile "terraform/stacks/capstone-ambientes-ws/main.tf" @'
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
'@

Write-RepoFile "terraform/stacks/capstone-ambientes-ws/dev.tfvars" @'
external_port = 8081
'@

Write-RepoFile "terraform/stacks/capstone-ambientes-ws/prod.tfvars" @'
external_port = 8082
'@
```

## Passo 2 — rodar com workspaces

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

## Passo 3 — a armadilha (o ponto do lab)

A Teoria disse que não existe barreira entre workspaces. Agora **provoque o
erro de propósito** — aplique a config de dev estando no workspace de prod:

```powershell
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace select prod
terraform -chdir=terraform/stacks/capstone-ambientes-ws apply -auto-approve -var-file="dev.tfvars"
```

Repare no que **não** aconteceu: nenhum aviso, nenhuma confirmação extra,
nenhum "você tem certeza que quer mexer em prod?". O Terraform obedeceu.

Desfaça:

```powershell
terraform -chdir=terraform/stacks/capstone-ambientes-ws apply -auto-approve -var-file="prod.tfvars"
```

> Neste lab o estrago é um container local. Com backend e credenciais reais,
> o mesmo comando teria mexido em produção de verdade — e o único obstáculo
> teria sido você lembrar de rodar `workspace select`. Ver Notas: aqui o
> `prod` chegou a ficar **fora do ar**.

## Passo 4 — refaça do jeito certo

> **Destrua os Passos 1-3 antes de continuar.** Os containers `lab13-dev` e
> `lab13-prod` dos passos anteriores usam os **mesmos nomes literais** que este passo
> vai criar — e o Docker é um daemon único e compartilhado, sem noção de
> "isso veio de um state diferente". Se não destruir agora, o `apply` deste
> passo falha com `Conflict: the container name ... is already in use`,
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

Os Passos 1–3 já foram destruídos antes do Passo 4 (passo acima) — só sobra
remover os workspaces vazios e o Passo 4:

```powershell
terraform -chdir=terraform/envs/dev destroy -auto-approve
terraform -chdir=terraform/envs/prod destroy -auto-approve

terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace delete dev
terraform -chdir=terraform/stacks/capstone-ambientes-ws workspace delete prod
```

## Notas

- **Passos 1–2 confirmados com evidência, não só pelo output:** `lab13-dev`
  (8081) e `lab13-prod` (8082) rodando ao mesmo tempo, cada workspace com
  seu próprio state em `terraform.tfstate.d/` (2 recursos gerenciados cada).
- **O Passo 3 (a armadilha) foi mais dramático que o roteiro previa.** Aplicar `dev.tfvars`
  no workspace `prod` não só "confundiu a config" — mudou a porta
  (`external`), que força `replace` do container. O Terraform destruiu o
  `lab13-prod` antigo e falhou ao criar o novo: a porta 8081 já estava
  ocupada pelo `lab13-dev` de verdade, rodando fora dessa mesma operação.
  Resultado: **prod ficou fora do ar** (`docker ps` mostrou `lab13-prod` em
  `Created`, não `Up`) até o `apply -var-file="prod.tfvars"` corrigir e
  religar na porta certa. Não foi só risco teórico — foi incidente real,
  ainda que em Docker local.
- **Achado real de fluxo do lab, corrigido no README:** o Passo 4 colidiu
  de cara com os passos anteriores — `Error: Conflict. The container name "/lab13-dev"
  is already in use`. Os nomes são literais (`lab13-dev`, `lab13-prod`) nos
  dois exercícios, e o Docker não faz ideia de que vêm de states Terraform
  diferentes. A limpeza dos Passos 1–3, que só existia no final do README,
  precisa acontecer **antes** do Passo 4 — corrigido, com o passo de
  destroy movido pra logo antes dos arquivos de `envs/`.
- **Passo 4 confirmado:** depois da limpeza, os dois `apply` (`envs/dev` e
  `envs/prod`) criaram os 4 recursos cada (via módulo `webapp` do Lab 10) e
  os dois containers subiram ao mesmo tempo, sem qualquer conflito de nome
  — a estrutura por diretório realmente elimina a colisão que workspace não
  evita.
