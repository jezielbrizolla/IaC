# Terraform Lab 3 — dependências e o grafo

**~1h**

## Objetivo
Entender como o Terraform decide a ordem das coisas.

## Onde o código mora
`terraform/stacks/web-network/main.tf` — stack novo (não expande o `web-basic`).

## O stack

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
```

Quatro recursos, e o container referencia os três outros por **atributo**:
`docker_image.nginx.image_id`, `docker_network.app_net.name`,
`docker_volume.app_data.name`. Cada referência dessas cria uma aresta no grafo
de dependência — é assim que o Terraform sabe o que criar primeiro, sem você
declarar ordem nenhuma.

## Rodar

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-network init
terraform -chdir=terraform/stacks/web-network validate
terraform -chdir=terraform/stacks/web-network apply -auto-approve
```

Repare na ordem do `apply`: imagem, rede e volume primeiro (em paralelo, são
independentes entre si), container por último.

## Ver o grafo

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

## O experimento — trocar para `depends_on` explícito

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

**Conclusão a anotar:** dependência implícita (por referência de atributo) é a
regra; `depends_on` é a exceção — para quando existe uma dependência real que o
Terraform não consegue enxergar na config. O exemplo clássico: uma IAM policy
que precisa existir antes de um serviço conseguir usá-la, sem que haja
referência de atributo entre os dois.

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
