# Terraform Lab 1 — workflow core

**~1h · essencial**

## Objetivo
O ciclo completo, e entender o que é o state.

## O que escrever
- `terraform { required_providers { docker = { source = "kreuzwerker/docker" } } }`
- `provider "docker" {}`
- `resource "docker_image"` + `resource "docker_container"` rodando nginx na porta 8080

## Rodar
```
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform destroy
```

## O passo que mais rende
Depois do `apply`, **abra o `terraform.tfstate` no editor e leia**. É JSON.
Procure: `resources[]`, `instances[]`, `attributes`, `serial`, `lineage`.
Entender que o state é só um mapa entre a sua config e IDs do mundo real
desmistifica quase tudo que vem depois.

## Quebre isto
Com o container no ar, **apague o `terraform.tfstate`** e rode `terraform plan`.
O Terraform vai querer criar tudo de novo — porque perdeu o mapa, não porque
o recurso sumiu. Limpe com `docker rm -f` na mão (ou volte aqui depois do Lab 6 de state
e resolva com `import`).

## Critério de conclusão
localhost:8080 serve o nginx, e o `destroy` deixa `docker ps -a` limpo.

## Notas
