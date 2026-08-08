# Terraform Lab 4 — count vs for_each e lifecycle

**~1h · essencial**

## Objetivo
O experimento que ensina de vez por que `for_each` quase sempre ganha.

## Teoria

**O problema: criar N coisas parecidas sem escrever N blocos.** Você precisa
de três containers, ou de um por tenant. Copiar o bloco `resource` três vezes
funciona, mas não escala e não permite que a lista venha de uma variável.

O Terraform tem dois **meta-arguments** pra isso — `count` e `for_each` — e
escolher errado entre eles é uma das causas mais comuns de incidente em
produção com Terraform.

**A diferença é o que forma a identidade do recurso no state.**

| | `count` | `for_each` |
|---|---|---|
| Aceita | número | mapa ou `set` |
| Identidade no state | **posição** — `app[0]`, `app[1]` | **chave** — `app["a"]`, `app["b"]` |
| Referência interna | `count.index` | `each.key` / `each.value` |

**Por que isso importa tanto.** Suponha `["a", "b", "c"]` com `count`. O state
guarda `app[0]=a`, `app[1]=b`, `app[2]=c`. Agora você remove `"b"` do meio:

```text
antes:  ["a", "b", "c"]  →  app[0]=a  app[1]=b  app[2]=c
depois: ["a", "c"]       →  app[0]=a  app[1]=c
```

O Terraform compara posição por posição. Ele vê que `app[1]` era `b` e agora
deve ser `c` — então quer **destruir e recriar** o `app[1]`. E `app[2]` sumiu,
então destrói também. Você removeu **um** item e o Terraform mexe em **dois**
recursos, incluindo um (`c`) que você não tocou.

Com `for_each`, a identidade é a chave: `app["b"]` simplesmente deixa de
existir. `app["a"]` e `app["c"]` nem aparecem no plan.

> **A regra:** use `for_each` sempre que os itens tiverem **identidade
> própria** — tenants, ambientes, aplicações, redes. Use `count` só para
> réplicas realmente intercambiáveis (N workers idênticos sem estado), ou como
> liga/desliga: `count = var.enabled ? 1 : 0`.

**`lifecycle` — os guardrails.** Bloco que muda *como* o Terraform trata o
recurso, sem mudar o que ele é:

- **`create_before_destroy = true`** — ao substituir, cria o novo antes de
  destruir o velho (inverte a ordem padrão). É como se evita downtime em
  recurso que precisa ser recriado.
- **`ignore_changes = [atributo]`** — o Terraform para de acusar drift naquele
  atributo. Útil quando algo externo altera legitimamente o recurso (um
  autoscaler mudando a contagem, uma tag adicionada por política).
- **`prevent_destroy = true`** — o `destroy` falha com erro em vez de
  executar. Proteção pra recurso crítico (banco de produção, golden image).

> **Conexão com o objetivo:** o mapa do `for_each` é o padrão de tenant —
> cada entrada é um tenant, adicionar uma linha provisiona um novo, remover
> destrói só aquele. Sem isso, um tenant removido do meio da lista derrubaria
> os tenants seguintes.

## O que vamos criar

`terraform/stacks/web-count-foreach/` — `main.tf` (imagem compartilhada) +
`count.tf` (evolui durante o lab: primeiro `count`, depois `for_each`).

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

Write-RepoFile "terraform/stacks/web-count-foreach/main.tf" @'
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
'@

# count.tf — versão inicial, com `count`. Vai evoluir durante o lab.
Write-RepoFile "terraform/stacks/web-count-foreach/count.tf" @'
variable "apps" {
  type    = list(string)
  default = ["a", "b", "c"]
}

resource "docker_container" "app" {
  count = length(var.apps)
  name  = "lab09-${var.apps[count.index]}"
  image = docker_image.nginx.image_id
}
'@
```

## Passo 2 — Experimento 1: o problema do `count`

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-count-foreach init
terraform -chdir=terraform/stacks/web-count-foreach apply -auto-approve
terraform -chdir=terraform/stacks/web-count-foreach state list
```

Agora **remova `"b"`** da lista (fica `["a", "c"]`):

```powershell
terraform -chdir=terraform/stacks/web-count-foreach plan
```

**Não aplique.** Leia com atenção: o Terraform quer **destruir e recriar** o
`docker_container.app[2]` (que era `"c"`), porque com `count` a identidade é o
**índice** — ao remover o índice 1, tudo depois dele "escorrega" uma posição.

## Passo 3 — Experimento 2: `for_each` resolve

Substitua o `resource` de `count.tf` pela versão com `for_each` (mesmo
arquivo, ou um `foreach.tf` separado — tanto faz, é a mesma pasta):

```hcl
variable "apps" {
  type    = set(string)
  default = ["a", "b", "c"]
}

resource "docker_container" "app" {
  for_each = var.apps
  name     = "lab09-${each.key}"
  image    = docker_image.nginx.image_id
}
```

```powershell
terraform -chdir=terraform/stacks/web-count-foreach apply -auto-approve
```

Remova `"b"` da lista, `terraform plan`. Agora **só o `"b"` é destruído** — os
outros dois nem aparecem no plan. Com `for_each` a identidade é a **chave**.

Anote a diferença com suas palavras nas Notas. Isso cai na prova e, mais
importante, é a diferença entre um deploy tranquilo e um incidente em produção.

## Passo 4 — Experimento 3: `lifecycle`

Adicione ao `resource "docker_container" "app"`:

```hcl
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [image]
  }
```

- `create_before_destroy = true` — force uma recriação (mude `name`) e veja a
  ordem do plan inverter (cria o novo antes de destruir o velho).
- `ignore_changes = [image]` — troque a tag da imagem (`nginx:1.25` em vez de
  `nginx:latest`) e veja o `plan` ficar vazio para esse atributo.
- Teste também `prevent_destroy = true` isoladamente: tente
  `terraform -chdir=terraform/stacks/web-count-foreach destroy` e leia o erro.
  Remova antes de seguir, senão você não consegue limpar o lab.

## Critério de conclusão
Você consegue explicar, sem consultar, quando `count` ainda é a escolha
certa — dica: quando são realmente "N cópias idênticas e intercambiáveis",
sem identidade própria (ex: réplicas puras de um worker sem estado).

## Limpeza

```powershell
terraform -chdir=terraform/stacks/web-count-foreach destroy -auto-approve
```

## Notas

- **`count` reproduziu o problema exatamente como esperado:** remover `"b"`
  do meio da lista fez o `plan` propor destruir/recriar `app[2]` (que era
  `"c"`, sem nenhuma relação com o item removido) — a prova concreta de que
  com `count` a identidade é posição, não conteúdo.
- **`for_each` isolou a remoção corretamente:** com o mesmo cenário (remover
  `"b"`), só `docker_container.app["b"]` apareceu no plan de destroy; `"a"` e
  `"c"` nem foram tocados.
- **`create_before_destroy` inverteu a ordem do plan** na recriação forçada —
  confirmado visualmente: o novo recurso aparece como `create` antes do
  `destroy` do antigo, ao contrário do padrão (`destroy` primeiro).
- **`ignore_changes = [image]` silenciou a mudança de tag** como esperado —
  trocar a imagem não gerou diff no plan para aquele atributo.
- **`prevent_destroy = true` bloqueou o `destroy`** com erro, e foi removido
  em seguida — sem isso, o `terraform.tfstate` ficaria travado impedindo a
  limpeza final do stack.
- **Quando usar `count` em vez de `for_each`:** Usaria o `count` apenas quando
  preciso de N cópias idênticas e totalmente intercambiáveis de um mesmo
  recurso, onde a identidade individual de cada uma não importa. Exemplo ideal:
  escalamento horizontal de réplicas de um worker sem estado (ex: count = 5
  instâncias idênticas processando uma fila). Nenhuma instância possui um nome,
  chave ou dado único. Se o count cair de 5 para 4, não importa qual instância
  específica é destruída, pois todas fazem exatamente a mesma função. Também
  útil como chave liga/desliga (count = var.enable_feature ? 1 : 0). Por que
  NÃO usar count para coisas com identidade (como tenants/apps)? Porque o count
  indexa os recursos por posição numérica no array ([0], [1], [2]). Se um item
  do meio for removido, todos os índices seguintes escorregam, fazendo o
  Terraform destruir e recriar recursos que não deveriam ter sido tocados. Para
  qualquer recurso com identidade própria (ambientes, tenants, redes), o
  `for_each` é a escolha certa por indexar por chave explícita (["tenant-a"]).
