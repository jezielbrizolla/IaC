# Terraform Lab 1 — workflow core

**~1h · essencial**

## Objetivo
O ciclo completo, e entender o que é o state.

## Onde o código mora
`terraform/stacks/web-basic/main.tf`

Um **stack** é uma unidade independente de infraestrutura, com seu próprio state.
No shape do repo, cada stack é um diretório em `terraform/stacks/`.

## O que transfere do Packer

| Packer | Terraform | Mesmo papel? |
|---|---|---|
| `packer { required_plugins {} }` | `terraform { required_providers {} }` | Sim — declara com o quê falar |
| `packer init` | `terraform init` | Sim — baixa o plugin/provider |
| `packer fmt` / `validate` | `terraform fmt` / `validate` | Idênticos |
| `packer build` | `terraform apply` | **Não** — e a diferença é o ponto deste lab |

Packer é **imutável**: roda uma vez, produz artefato, esquece. Terraform é
**convergente**: guarda um mapa do que criou (o **state**) e a cada execução
compara o declarado com o que existe de verdade.

## O stack
`terraform/stacks/web-basic/main.tf`:
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
```

Três blocos:
- `terraform {}` — versão mínima do CLI e quais providers baixar. Análogo ao
  `packer {}`.
- `provider "docker" {}` — configura como falar com o Docker. Vazio aqui porque
  o provider acha o daemon local sozinho.
- `resource` — **o estado desejado**. Você declara o que deve existir; o
  Terraform descobre como chegar lá. Repare que `docker_container.web`
  referencia `docker_image.nginx.image_id` — isso cria uma dependência
  implícita, o Terraform sabe que precisa criar a imagem antes do container.

`keep_locally = true` evita que o `destroy` apague a imagem local (senão você
re-baixa o nginx toda vez).

> Sobre o bloco `ports`: só `internal` é obrigatório. `external` é
> `optional + computed` no schema do provider — se você omitir, o Docker
> atribui uma porta aleatória no host e o Terraform grava ela no state. Ou
> seja, omitir não significa "não expõe", significa "expõe numa porta que
> você não escolheu" — sintoma diferente na hora de debugar.

## Rodar

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

Não destrua ainda — o passo abaixo precisa do state existindo.

## O passo que mais rende

Depois do `apply`, **abra `terraform/stacks/web-basic/terraform.tfstate` e leia**.
É JSON puro.

```powershell
Get-Content terraform/stacks/web-basic/terraform.tfstate | ConvertFrom-Json |
  Select-Object -ExpandProperty resources | Select-Object type, name
```

Procure `resources[].instances[0].attributes` e compare com o que aparece em
`docker inspect lab06-web`. Note também:
- `serial` — contador que incrementa a cada mudança
- `lineage` — ID único deste state, usado para detectar se você trocou de state
  por engano

Entender que o state é **só um mapa entre a sua config e IDs do mundo real**
desmistifica quase tudo que vem depois — drift, import, `moved`, tudo parte daí.

## Quebre isto
1. Com o container no ar, faça backup e apague o state:
   ```powershell
   Copy-Item terraform/stacks/web-basic/terraform.tfstate terraform/stacks/web-basic/terraform.tfstate.bak
   Remove-Item terraform/stacks/web-basic/terraform.tfstate
   terraform -chdir=terraform/stacks/web-basic plan
   ```
2. Leia a saída: o Terraform quer **criar tudo de novo** — não porque o recurso
   sumiu (`docker ps` mostra o container vivo), mas porque ele perdeu o mapa.
   Sem state, o Terraform é cego: ele não inspeciona o mundo procurando o que
   ele criou, ele confia no arquivo.
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
