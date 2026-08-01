# Terraform Lab 1 — workflow core

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h · essencial**

## Objetivo
O ciclo completo, e entender o que é o state.

## Arquivos a criar

`main.tf`:
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

## Rodar
```powershell
cd labs\06-tf-workflow-core
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply -auto-approve
curl http://localhost:8080
terraform destroy -auto-approve
```

## O passo que mais rende
Depois do `apply` (antes do `destroy`!), **abra `terraform.tfstate` no editor e leia**.
É JSON puro. Procure:
```powershell
Get-Content terraform.tfstate | ConvertFrom-Json | Select-Object -ExpandProperty resources | Select-Object type, name
```
Ache `resources[].instances[0].attributes` — compare os valores com o que você vê em
`docker inspect lab06-web`. Note também `serial` (contador de mudanças) e `lineage`
(ID único deste state). Entender que o state é só um mapa entre a sua config e IDs do
mundo real desmistifica quase tudo que vem depois.

## Quebre isto
1. Com o container no ar (depois do `apply`), faça backup e apague o state:
   ```powershell
   Copy-Item terraform.tfstate terraform.tfstate.bak
   Remove-Item terraform.tfstate
   terraform plan
   ```
2. Leia a saída: o Terraform quer **criar tudo de novo** — porque perdeu o mapa,
   não porque o recurso sumiu (`docker ps` ainda mostra o container rodando).
3. Limpe manualmente: `docker rm -f lab06-web` e `Remove-Item terraform.tfstate.bak`.
   (Depois de fazer o Lab 11 de state, volte aqui e resolva o mesmo cenário com `import`.)

## Critério de conclusão
`curl http://localhost:8080` retorna a página padrão do nginx, e `terraform destroy`
deixa `docker ps -a` sem o container.

## Notas
