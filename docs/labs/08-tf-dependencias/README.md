# Terraform Lab 3 — dependências e o grafo

**~1h**

## Objetivo
Entender como o Terraform decide a ordem das coisas.

## Teoria

**Você nunca declara ordem no Terraform.** Isso é diferente do Packer, onde a
ordem dos provisioners é literalmente a ordem de execução (Lab 02). Aqui, você
declara *o que deve existir*, e o Terraform descobre sozinho a sequência.

**Como ele descobre: o grafo de dependência.** Toda vez que um recurso
referencia um atributo de outro — `docker_container.web` usando
`docker_network.app_net.name` — o Terraform registra uma **aresta**: "o
container depende da rede". Juntando todas as arestas, ele monta um grafo
dirigido, e percorre em ordem topológica: o que não depende de nada vai
primeiro, em paralelo; o que depende, espera.

Isso é **dependência implícita**, e é a forma correta na esmagadora maioria
dos casos. Você não pediu nada; ela emerge de você ter usado o valor.

**`depends_on` é a exceção, não a alternativa.** Existe pra quando há uma
dependência **real** que o Terraform não consegue enxergar, porque não passa
por referência de atributo nenhuma. O exemplo clássico: uma IAM policy que
precisa existir antes de um serviço conseguir usá-la, sem que haja referência
direta entre os dois recursos no código.

Usar `depends_on` quando já existe referência de atributo é redundante — e
sinal de que quem escreveu não entendeu o mecanismo.

**Ciclo = erro fatal.** Se A depende de B e B depende de A, não existe ponto
de partida. Ordenação topológica exige um grafo **acíclico** — por isso o
Terraform aborta com `Cycle: ...` em vez de tentar adivinhar.

**O grafo também vale pro destroy**, percorrido ao contrário: destrói primeiro
quem depende, depois quem é dependido. Você já viu isso no Lab 06, quando o
container foi destruído antes da imagem.

## O que vamos criar

`terraform/stacks/web-network/main.tf` — stack novo (não expande o
`web-basic`).

Quatro recursos, e o container referencia os três outros por **atributo**:
`docker_image.nginx.image_id`, `docker_network.app_net.name`,
`docker_volume.app_data.name`. Cada referência dessas cria uma aresta no grafo
de dependência — é assim que o Terraform sabe o que criar primeiro, sem você
declarar ordem nenhuma.

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

Write-RepoFile "terraform/stacks/web-network/main.tf" @'
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

resource "docker_network" "app_net" {
  name = "lab08-net"
}

resource "docker_volume" "app_data" {
  name = "lab08-data"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "lab08-web"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.app_net.name
  }

  volumes {
    volume_name    = docker_volume.app_data.name
    container_path = "/usr/share/nginx/html"
  }
}
'@
```

## Passo 2 — rodar

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-network init
terraform -chdir=terraform/stacks/web-network validate
terraform -chdir=terraform/stacks/web-network apply -auto-approve
```

Repare na ordem do `apply`: imagem, rede e volume primeiro (em paralelo, são
independentes entre si), container por último.

## Passo 3 — ver o grafo

`terraform graph` gera o grafo em formato DOT. Funciona **sem precisar de
apply** — ele lê da config, não do state. Mas precisa de `init` antes (precisa
do schema do provider).

```powershell
terraform -chdir=terraform/stacks/web-network graph > graph.dot
Get-Content graph.dot | Select-String "->" | Select-String "docker_container"
```

Você vai ver as três arestas:

```text
"docker_container.web" -> "docker_image.nginx";
"docker_container.web" -> "docker_network.app_net";
"docker_container.web" -> "docker_volume.app_data";
```

A seta `A -> B` significa "A depende de B", ou seja, **B é criado antes de A**.

Para ver desenhado, cole o conteúdo de `graph.dot` em
<https://dreampuf.github.io/GraphvizOnline>.

## Passo 4 — o experimento: `depends_on` explícito

Substitua o bloco do container por esta versão, que remove as referências de
atributo e declara a ordem na mão:

```hcl
resource "docker_container" "web" {
  name  = "lab08-web"
  image = docker_image.nginx.image_id

  depends_on = [
    docker_network.app_net,
    docker_volume.app_data,
  ]
}
```

Rode o `graph` de novo e compare.

> **O que você vai descobrir:** o grafo é **idêntico**. As mesmas três arestas,
> na mesma direção. Isso surpreende, mas faz sentido — `depends_on` e a
> referência de atributo produzem a mesma aresta de ordenação.
>
> **A diferença real não está no grafo, está no que passa pela aresta.** A
> referência de atributo faz duas coisas: ordena *e* **transporta o valor**
> (o nome da rede vai parar dentro do container). O `depends_on` só ordena —
> repare que nesta versão o container **não está mais conectado** à rede nem
> ao volume, porque os blocos `networks_advanced` e `volumes` sumiram junto
> com as referências. Ele espera a rede existir e depois a ignora.

Depois **volte para a versão com referência de atributo** — é a correta.

Isso fecha o ponto da Teoria: `depends_on` não é "a outra forma de fazer a
mesma coisa". Ele ordena sem conectar. Se você tem a referência disponível,
usá-la é sempre melhor — você ganha a ordenação *e* o dado.

## Quebre isto — dependência circular

Crie um arquivo `circular.tf` no mesmo stack, só para provocar o erro:

```hcl
resource "terraform_data" "a" {
  input = terraform_data.b.output
}

resource "terraform_data" "b" {
  input = terraform_data.a.output
}
```

Rode:

```powershell
terraform -chdir=terraform/stacks/web-network validate
```

```text
Error: Cycle: terraform_data.b, terraform_data.a
```

O Terraform não consegue ordenar: A precisa de B, B precisa de A. Não há ponto
de partida. Em grafo, isso é um ciclo — e o algoritmo de ordenação topológica
que o Terraform usa exige um grafo **acíclico**.

> `terraform_data` é um recurso **built-in** (desde o Terraform 1.4) que não
> faz nada — existe para casos assim, ou para forçar recriação via `triggers`.
> Ele substituiu o `null_resource`, que exigia o provider `hashicorp/null`.
> Aqui isso importa na prática: com `null_resource`, você bateria primeiro num
> `Error: Missing required provider` e teria que rodar `terraform init` de
> novo antes de conseguir ver o erro de ciclo. Com `terraform_data`, o ciclo
> aparece direto.

Apague o `circular.tf` antes de seguir.

## Critério de conclusão
Você consegue apontar no `graph.dot` por que a rede é criada antes do
container, entendeu por que o grafo não muda com `depends_on`, e provocou o
erro de ciclo.

## Limpeza

```powershell
terraform -chdir=terraform/stacks/web-network destroy -auto-approve
```

## Notas

- **Grafo idêntico confirmado na prática.** As três arestas
  (`docker_container.web -> docker_image.nginx / docker_network.app_net /
  docker_volume.app_data`) apareceram exatamente iguais nas duas versões —
  com referência de atributo e com `depends_on`. A diferença fica só no
  container real: com `depends_on`, ele sobe sem estar de fato ligado à rede
  nem ao volume, porque os blocos `networks_advanced`/`volumes` saem junto
  com a referência.
- **Editar "substitua o bloco X" ao vivo é fácil de fazer pela metade.** Na
  troca para `depends_on`, sobrou um `volumes { ... }` órfão colado depois do
  `}` que já fechava o recurso — arquivo com chave a mais, teria falhado no
  `validate`. Pego a tempo antes de rodar. Lição prática: ao substituir um
  bloco inteiro, conferir que **todo** o bloco antigo saiu, não só o topo.
- **`terraform apply` "0 added" na primeira leitura pareceu bug.** O state
  tinha `serial: 6` logo de cara, e o container já existia no Docker antes do
  `apply` que gerou o output. Não é bug: o backend local grava o state a cada
  operação (refresh, cada recurso criado), então um único `apply` de 4
  recursos facilmente sobe o serial em várias unidades. O apply colado foi
  uma segunda chamada (idempotente) sobre um state que já refletia a infra
  real de uma tentativa anterior.
