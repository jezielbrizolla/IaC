# Terraform Lab 4 — count vs for_each e lifecycle

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h · essencial**

## Objetivo
O experimento que ensina de vez por que `for_each` quase sempre ganha.

## Base comum

`main.tf` (imagem compartilhada):
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
```

## Experimento 1 — count

`count.tf`:
```hcl
variable "apps" {
  type    = list(string)
  default = ["a", "b", "c"]
}

resource "docker_container" "app" {
  count = length(var.apps)
  name  = "lab09-${var.apps[count.index]}"
  image = docker_image.nginx.image_id
}
```
```powershell
terraform init
terraform apply -auto-approve
terraform state list
```
Agora **remova `"b"`** da lista (fica `["a", "c"]`):
```powershell
terraform plan
```
**Não aplique.** Leia com atenção: o Terraform quer **destruir e recriar** o
`docker_container.app[2]` (que era `"c"`), porque com `count` a identidade é o
**índice** — ao remover o índice 1, tudo depois dele "escorrega" uma posição.

```powershell
terraform destroy -auto-approve
```

## Experimento 2 — for_each

Substitua `count.tf` por `foreach.tf`:
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
terraform apply -auto-approve
```
Remova `"b"` da lista, `terraform plan`. Agora **só o `"b"` é destruído** — os
outros dois nem aparecem no plan. Com `for_each` a identidade é a **chave**.

Anote a diferença com suas palavras nas Notas. Isso cai na prova e, mais
importante, é a diferença entre um deploy tranquilo e um incidente em produção.

## Experimento 3 — lifecycle
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
- Teste também `prevent_destroy = true` isoladamente: tente `terraform destroy`
  e leia o erro. Remova antes de seguir, senão você não consegue limpar o lab.

## Critério de conclusão
Você consegue explicar, sem consultar, quando `count` ainda é a escolha certa —
dica: quando são realmente "N cópias idênticas e intercambiáveis", sem identidade
própria (ex: réplicas puras de um worker sem estado).

## Notas
