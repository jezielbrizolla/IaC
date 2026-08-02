# Terraform Lab 3 — dependências e o grafo

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h**

## Objetivo
Entender como o Terraform decide a ordem das coisas.

## Arquivos a criar

`main.tf` — versão com dependência **implícita** (a regra):
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

## Rodar
```powershell
cd labs\08-tf-dependencias
terraform init
terraform apply -auto-approve
terraform graph > graph.dot
Get-Content graph.dot
```
Cole o conteúdo de `graph.dot` em <https://dreampuf.github.io/GraphvizOnline> para ver
o desenho, ou leia o texto mesmo — procure as linhas `->` que ligam
`docker_container.web` a `docker_network.app_net` e `docker_volume.app_data`.

## O experimento — trocar para depends_on explícito
Substitua as referências por valores fixos e adicione `depends_on`:
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
Rode `terraform graph` de novo e compare. Depois **volte para a versão com
referência de atributo** — é a versão correta; esta foi só para comparar o grafo.

**Conclusão a anotar:** dependência implícita (por referência de atributo) é a regra;
`depends_on` é a exceção — para quando existe uma dependência real que o Terraform
não consegue enxergar na config (ex: uma IAM policy que precisa existir antes de um
serviço conseguir usá-la, sem que haja referência de atributo entre os dois).

## Quebre isto — dependência circular
Crie um arquivo separado `circular.tf` (delete depois) só para provocar o erro:
```hcl
resource "null_resource" "a" {
  triggers = {
    b_id = null_resource.b.id
  }
}

resource "null_resource" "b" {
  triggers = {
    a_id = null_resource.a.id
  }
}
```
Rode `terraform validate` ou `terraform plan` e leia o erro `Cycle: ...`.
Apague `circular.tf` antes de seguir (e rode `terraform init` de novo se precisar
do provider `null`: adicione `hashicorp/null` a `required_providers` primeiro).

## Critério de conclusão
Você consegue apontar no `graph.dot` por que a rede é criada antes do container,
e provocou/leu o erro de ciclo.

## Notas
