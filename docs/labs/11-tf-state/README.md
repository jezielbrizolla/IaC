# Terraform Lab 6 — state na prática

**~1h · o que separa júnior de sênior**

## Objetivo
Operar o state com confiança. É o lab mais denso do bloco — reserve a sessão longa.

## Teoria

**O Lab 06 explicou o que o state é. Este lab é sobre operá-lo** — as quatro
situações reais em que você precisa mexer no mapa sem destruir o território.

**1. `import` — trazer pra dentro o que já existe.** Cenário: alguém criou um
recurso na mão, ou você está adotando infra que já rodava antes do Terraform.
O recurso existe, mas o Terraform não sabe. `terraform import` adiciona ele ao
state.

O detalhe que surpreende: **`import` não escreve código pra você** (na forma
clássica). Ele preenche o state; você precisa escrever o bloco `resource`
correspondente à mão, e ir ajustando até o `plan` ficar **vazio**. Se o plan
não zera, seu código não descreve o que existe de verdade — e aplicar iria
modificar o recurso.

> O Terraform ≥ 1.5 tem o bloco `import {}` + `-generate-config-out`, que gera
> o HCL automaticamente. Vale conhecer os dois caminhos.

**2. Drift — quando a realidade muda por fora.** Alguém parou o container pelo
console, um autoscaler mudou a contagem, um script mexeu numa tag. O state diz
uma coisa, o mundo diz outra. O `plan` detecta e propõe **desfazer** a mudança
externa (voltar ao declarado).

Aqui entra `terraform plan -refresh-only`: em vez de propor mudar o mundo, ele
propõe **atualizar o state** pra refletir a realidade. É a ferramenta de
auditoria — "o que mudou por fora?" — sem risco de aplicar nada.

**3. `moved` e `state mv` — renomear sem destruir.** Você renomeia
`docker_container.app` para `docker_container.web` no código. Pro Terraform,
isso não é rename — é *um recurso que sumiu e outro que apareceu*. O plan
propõe destruir e criar. Em produção isso é downtime por causa de refactor.

Duas formas de resolver:

| | `terraform state mv` | bloco `moved {}` |
|---|---|---|
| Natureza | comando imperativo | declarativo, no código |
| Fica registrado? | não — só no seu histórico de shell | **sim**, versionado |
| Vale pra quem clonar? | não | sim |

**Prefira `moved {}`.** Ele fica no código, então quem der `pull` também
renomeia corretamente, sem precisar rodar comando nenhum.

**4. `state rm` — remover do controle sem destruir.** Isto **não apaga o
recurso real**. Tira do state, e o Terraform passa a ignorar aquele recurso
como se nunca tivesse existido.

Serve pra migrar um recurso entre configs, ou pra "soltar" algo que outro time
vai assumir. E é perigoso pela mesma razão: o recurso continua existindo (e
sendo cobrado), só que agora ninguém o gerencia — é como se cria infra órfã de
propósito.

> **`state rm` vs `destroy`:** `destroy` apaga o recurso real e remove do
> state. `state rm` só remove do state. É a mesma distinção que o Lab 06
> mostrou com `keep_locally = true`, onde "Destroyed" no output não significou
> imagem apagada.
>
> **Conexão com o objetivo:** com N tenants, o state fica separado por tenant
> ou por stack? O que acontece com os outros se o state de um corromper?

## O que vamos criar

`terraform/stacks/web-state/main.tf` — um stack simples de propósito. O
conteúdo importa menos que as operações que vamos fazer sobre ele.

## Passo 1 — criar a base

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

Write-RepoFile "terraform/stacks/web-state/main.tf" @'
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

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "app" {
  name  = "lab11-app"
  image = docker_image.nginx.image_id
}
'@
```

```powershell
terraform -chdir=terraform/stacks/web-state init
terraform -chdir=terraform/stacks/web-state apply -auto-approve
```

## Passo 2 — inspeção

```powershell
terraform -chdir=terraform/stacks/web-state state list
terraform -chdir=terraform/stacks/web-state state show docker_container.app
```

## Passo 3 — import

1. Crie um container **fora** do Terraform:

   ```powershell
   docker run -d --name orfao -p 9090:80 nginx
   ```

2. Adicione o bloco correspondente a `terraform/stacks/web-state/main.tf`
   (só declare, **não** rode `apply`):

   ```hcl
   resource "docker_container" "orfao" {
     name  = "orfao"
     image = docker_image.nginx.image_id
   }
   ```

3. Importe:

   ```powershell
   $cid = docker inspect -f '{{.Id}}' orfao
   terraform -chdir=terraform/stacks/web-state import docker_container.orfao $cid
   ```

4. `terraform -chdir=terraform/stacks/web-state plan` — vai mostrar
   diferenças (portas, labels, etc. que você não declarou). Ajuste a config
   até o plan ficar **vazio**. Esse ajuste é o exercício real: você está
   descobrindo o estado verdadeiro do recurso a partir do que já existe —
   não confie na primeira config que você escreveu de cabeça, confie no que
   o `plan` te mostra depois do import.

> Alternativa moderna (Terraform ≥ 1.5): bloco
> `import { to = docker_container.orfao, id = "..." }` no código, seguido de
> `terraform plan -generate-config-out=gerado.tf`, que já escreve a config
> para você. Vale testar as duas formas.

## Passo 4 — drift

```powershell
docker stop orfao
terraform -chdir=terraform/stacks/web-state plan
```

O Terraform detecta que o container não está mais rodando e propõe corrigir.
Agora compare com:

```powershell
terraform -chdir=terraform/stacks/web-state plan -refresh-only
```

Aqui ele só reconcilia o **state** com a realidade (mostra o que mudou), sem
propor nenhuma ação para mudar a realidade de volta.

## Passo 5 — `moved` e `state mv`

1. Renomeie `docker_container.app` para `docker_container.web` no `main.tf`.
2. `terraform -chdir=terraform/stacks/web-state plan` → ele quer **destruir e
   criar**. Não aplique.
3. Resolva de duas formas (desfaça uma antes de testar a outra):
   - Imperativo:
     `terraform -chdir=terraform/stacks/web-state state mv docker_container.app docker_container.web`
   - Declarativo (prefira este — fica registrado no código, versionado):

     ```hcl
     moved {
       from = docker_container.app
       to   = docker_container.web
     }
     ```

4. `terraform -chdir=terraform/stacks/web-state plan` de novo — deve ficar vazio.

## Passo 6 — `state rm`

```powershell
terraform -chdir=terraform/stacks/web-state state rm docker_container.orfao
docker ps --filter "name=orfao"
```

O container `orfao` continua vivo — `state rm` tira do state **sem destruir** o
recurso real. Pense em quando isso ajuda (migrar um recurso entre configs
distintas) e quando é perigoso (esquecer que ele existe e continuar "pagando"
por ele sem o Terraform gerenciar).

## Critério de conclusão
Você fez um `import`, chegou a plan vazio, e sabe explicar a diferença entre
`state rm` e `destroy` sem pensar.

## Limpeza

```powershell
docker rm -f orfao
terraform -chdir=terraform/stacks/web-state destroy -auto-approve
```

## Notas

- **Parte 1 (inspeção):** `state list` mostrou `docker_container.app` e
  `docker_image.nginx`. `state show docker_container.app` revelou o snapshot
  completo do recurso no state (id, hostname, network_data, etc.).
- **Parte 2 (import):** container `orfao` criado fora do Terraform e
  importado com sucesso via `terraform import docker_container.orfao $cid`.
  Config ajustada (portas, `start`, `must_run`, etc.) até o plan ficar vazio
  — o `image` importado veio como a tag literal (`nginx`), não o SHA que
  `docker_image.nginx.image_id` resolve, então bater os dois foi parte do
  ajuste.
- **Parte 3 (drift):** `docker stop orfao` causou drift detectado pelo plan
  (queria recriar). `plan -refresh-only` mostrou apenas as mudanças sem
  propor correção — útil para auditoria sem risco de aplicar nada.
- **Parte 4 (moved):** renomear `docker_container.app` para
  `docker_container.web` sem tratamento causou destroy/create. Bloco
  `moved { from = docker_container.app, to = docker_container.web }`
  resolveu — plan ficou vazio, renomeando sem destruir.
- **Parte 5 (state rm):** `terraform state rm docker_container.orfao` removeu
  do state, mas o container continuou rodando (`docker ps` confirmou).
  Diferença clara: `state rm` tira do controle, `destroy` destrói o recurso
  real.
- **Limpeza confirmada de verdade:** ao final, nenhum container `lab11-*` ou
  `orfao` restou no Docker, e o `terraform.tfstate` do stack ficou com 0
  recursos gerenciados — o `moved {}` block continua no `main.tf` (registro
  do rename), mas a declaração de `orfao` foi removida depois do `state rm`.
