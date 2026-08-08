# Terraform Lab 1 — workflow core

**~1h · essencial**

## Objetivo
O ciclo completo, e entender o que é o state.

## Teoria

**O que muda em relação ao Packer.** A estrutura do arquivo é familiar, e boa
parte transfere direto:

| Packer | Terraform | Mesmo papel? |
|---|---|---|
| `packer { required_plugins {} }` | `terraform { required_providers {} }` | Sim — declara com o quê falar |
| `packer init` | `terraform init` | Sim — baixa o plugin/provider |
| `packer fmt` / `validate` | `terraform fmt` / `validate` | Idênticos |
| `packer build` | `terraform apply` | **Não** — e a diferença é o ponto deste lab |

Packer é **imutável**: roda uma vez, produz um artefato, e esquece. Não tem
memória de execuções anteriores; rodar duas vezes produz duas imagens.

Terraform é **convergente**: ele guarda um mapa do que criou e, a cada
execução, compara o que você declarou com o que existe de verdade — e faz só
a diferença. Rodar duas vezes com o mesmo código não cria nada na segunda.

**Esse mapa é o `state`, e é o conceito central deste lab.**

**O que o state realmente é** (e não é): um arquivo JSON que diz *"o recurso
que eu chamo de `docker_container.web` é o objeto real de ID
`cfe25ba1767…`"*. Só isso. Não é mágica, não é banco de dados, não é
inventário do que existe na sua infra.

A consequência que surpreende: **sem o state, o Terraform é cego.** Ele não
sai vasculhando o mundo procurando coisas que ele criou — ele confia no
arquivo. Se você apagar o state com o container rodando, o Terraform vai
querer criar tudo de novo, porque perdeu o mapa. Em produção isso é
infraestrutura órfã: recursos rodando (e sendo cobrados) que ferramenta
nenhuma gerencia mais.

**O `plan` compara três coisas, não duas:**

```text
código (main.tf)  ←→  state (o mapa)  ←→  realidade (o refresh)
```

- **Código vs state divergem** → você mudou a config, o Terraform vai aplicar
- **State vs realidade divergem** → alguém mexeu por fora, isso é **drift**

Entender isso desmistifica quase tudo que vem depois — drift, `import`,
`moved`, state perdido são todos consequência direta desse desenho.

**Um `stack`** é uma unidade independente de infraestrutura, com seu próprio
state. No shape deste repo, cada stack é um diretório em `terraform/stacks/`.
Stacks separados = states separados = falhas isoladas.

## O que vamos criar

`terraform/stacks/web-basic/main.tf` — três blocos:

- **`terraform {}`** — versão mínima do CLI e quais providers baixar. Análogo
  ao `packer {}`.
- **`provider "docker" {}`** — configura como falar com o Docker. Vazio aqui
  porque o provider acha o daemon local sozinho.
- **`resource`** — **o estado desejado**. Você declara o que deve existir; o
  Terraform descobre como chegar lá.

Repare que `docker_container.web` referencia `docker_image.nginx.image_id` —
isso cria uma **dependência implícita**, e o Terraform sabe sozinho que
precisa criar a imagem antes do container. Esse mecanismo é o assunto do
Lab 08.

`keep_locally = true` evita que o `destroy` apague a imagem local (senão você
re-baixa o nginx toda vez).

> Sobre o bloco `ports`: só `internal` é obrigatório. `external` é
> `optional + computed` no schema do provider — se você omitir, o Docker
> atribui uma porta aleatória no host e o Terraform grava ela no state. Ou
> seja, omitir não significa "não expõe", significa "expõe numa porta que
> você não escolheu" — sintoma diferente na hora de debugar.

## Passo 1 — criar o stack

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

Write-RepoFile "terraform/stacks/web-basic/main.tf" @'
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

resource "docker_container" "web" {
  name  = "lab06-web"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8080
  }
}
'@
```

## Passo 2 — rodar o ciclo completo

O Terraform roda no diretório atual por padrão, mas aceita `-chdir` para rodar
de qualquer lugar — é assim que mantemos a regra de nunca precisar de `cd`:

```powershell
terraform -chdir=terraform/stacks/web-basic init
terraform -chdir=terraform/stacks/web-basic fmt
terraform -chdir=terraform/stacks/web-basic validate
terraform -chdir=terraform/stacks/web-basic plan
terraform -chdir=terraform/stacks/web-basic apply -auto-approve
curl http://localhost:8080
```

**Não destrua ainda** — o passo abaixo precisa do state existindo.

## Passo 3 — o passo que mais rende: leia o state

Depois do `apply`, **abra `terraform/stacks/web-basic/terraform.tfstate` e
leia**. É JSON puro.

```powershell
Get-Content terraform/stacks/web-basic/terraform.tfstate | ConvertFrom-Json |
  Select-Object -ExpandProperty resources | Select-Object type, name
```

Procure `resources[].instances[0].attributes` e **compare o `id` com o que
aparece em `docker inspect lab06-web --format '{{.Id}}'`** — são o mesmo
valor, caractere por caractere. Isso é a prova concreta de que o state é só
um mapa entre nome lógico e ID real.

Note também:

- `serial` — contador que incrementa a cada mudança
- `lineage` — ID único deste state, usado para detectar se você trocou de
  state por engano

## Quebre isto

1. Com o container no ar, faça backup e apague o state:

   ```powershell
   Copy-Item terraform/stacks/web-basic/terraform.tfstate terraform/stacks/web-basic/terraform.tfstate.bak
   Remove-Item terraform/stacks/web-basic/terraform.tfstate
   terraform -chdir=terraform/stacks/web-basic plan
   ```

2. Leia a saída: o Terraform quer **criar tudo de novo** — não porque o recurso
   sumiu (`docker ps` mostra o container vivo), mas porque ele perdeu o mapa.
3. Restaure o backup e destrua normalmente:

   ```powershell
   Move-Item terraform/stacks/web-basic/terraform.tfstate.bak terraform/stacks/web-basic/terraform.tfstate -Force
   terraform -chdir=terraform/stacks/web-basic destroy -auto-approve
   ```

> No Lab 11 (state) você resolve esse mesmo cenário com `terraform import`, em
> vez de restaurar backup.

## Critério de conclusão
`curl http://localhost:8080` retorna a página padrão do nginx, você leu o
`terraform.tfstate` e sabe explicar o que ele guarda, e o `destroy` deixa
`docker ps -a` sem o container.

## Limpeza

```powershell
terraform -chdir=terraform/stacks/web-basic destroy -auto-approve
```

> Este stack **continua sendo usado no Lab 07**, que o expande em vez de criar
> outro. Não apague os arquivos — só destrua os recursos.

## Notas

- **O `id` do state é literalmente o ID do Docker.** Comparei
  `docker inspect lab06-web --format '{{.Id}}'` com o que o `apply` reportou:
  `cfe25ba176773e7e3ed230d6e17d711292adfffc1b532f06fd202692fbb29db8`, idêntico
  caractere por caractere. O state não é mágico — é um JSON dizendo "o recurso
  que chamo de `docker_container.web` é o objeto real de ID X". Drift, import,
  `moved` e state perdido são todos consequência disso.
- **Sem state, o Terraform é cego.** No "Quebre isto", com o container vivo e a
  porta 8080 respondendo, o `plan` disse `2 to add` — ele não sai inspecionando
  o mundo procurando o que criou, ele confia no arquivo. Em produção isso é
  infraestrutura órfã: recursos rodando (e sendo cobrados) que ferramenta
  nenhuma gerencia mais.
- **A linha `Refreshing state...` só aparece quando há state.** É o Terraform
  perguntando ao provider o estado atual de cada recurso que ele conhece — e ele
  só sabe perguntar porque tem os IDs. Isso revela que o `plan` compara **três**
  coisas, não duas: o código (`main.tf`), o state (o mapa) e a realidade (o
  refresh). Drift = state vs realidade divergem. Mudança de código = código vs
  state divergem.
- **Ordem de exibição ≠ ordem de execução.** O `plan` lista `docker_container`
  antes de `docker_image` (alfabético), mas o `apply` criou a imagem primeiro
  (14s) e o container depois (1s). No `destroy` a ordem inverteu — container
  primeiro, imagem depois. O grafo de dependência é percorrido ao contrário
  para destruir.
- **"Destroyed" no output nem sempre significa apagado.** O destroy reportou
  `docker_image.nginx: Destroying...` e `2 destroyed`, mas `docker images nginx`
  mostra a imagem viva — porque `keep_locally = true`. "Destruir" ali significa
  **remover do state**, não deletar o artefato real. Essa distinção
  (remover do state ≠ destruir o recurso) é exatamente o que o
  `terraform state rm` explora de propósito no Lab 11.
