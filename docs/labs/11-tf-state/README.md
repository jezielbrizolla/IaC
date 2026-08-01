# Terraform Lab 6 — state na prática

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `terraform/stacks/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1h · o que separa júnior de sênior**

## Objetivo
Operar o state com confiança. É o lab mais denso do bloco — reserve a sessão longa.

## Base

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

resource "docker_container" "app" {
  name  = "lab11-app"
  image = docker_image.nginx.image_id
}
```
```powershell
cd labs\11-tf-state
terraform init
terraform apply -auto-approve
```

## Parte 1 — inspeção
```powershell
terraform state list
terraform state show docker_container.app
```

## Parte 2 — import
1. Crie um container **fora** do Terraform:
   ```powershell
   docker run -d --name orfao -p 9090:80 nginx
   ```
2. Adicione o bloco correspondente ao `.tf` (só declare, **não** rode `apply`):
   ```hcl
   resource "docker_container" "orfao" {
     name  = "orfao"
     image = docker_image.nginx.image_id
   }
   ```
3. Importe:
   ```powershell
   $cid = docker inspect -f '{{.Id}}' orfao
   terraform import docker_container.orfao $cid
   ```
4. `terraform plan` — vai mostrar diferenças (portas, labels, etc. que você não
   declarou). Ajuste a config até o plan ficar **vazio**. Esse ajuste é o
   exercício real: você está descobrindo o estado verdadeiro do recurso a partir
   do que já existe.

> Alternativa moderna (Terraform ≥ 1.5): bloco `import { to = docker_container.orfao, id = "..." }`
> no código, seguido de `terraform plan -generate-config-out=gerado.tf`, que já
> escreve a config para você. Vale testar as duas formas.

## Parte 3 — drift
```powershell
docker stop orfao
terraform plan
```
O Terraform detecta que o container não está mais rodando e propõe corrigir.
Agora compare com:
```powershell
terraform plan -refresh-only
```
Aqui ele só reconcilia o **state** com a realidade (mostra o que mudou), sem
propor nenhuma ação para mudar a realidade de volta.

## Parte 4 — mv e moved
1. Renomeie `docker_container.app` para `docker_container.web` no `.tf`.
2. `terraform plan` → ele quer **destruir e criar**. Não aplique.
3. Resolva de duas formas (desfaça uma antes de testar a outra):
   - Imperativo: `terraform state mv docker_container.app docker_container.web`
   - Declarativo (prefira este — fica registrado no código, versionado):
     ```hcl
     moved {
       from = docker_container.app
       to   = docker_container.web
     }
     ```
4. `terraform plan` de novo — deve ficar vazio.

## Parte 5 — rm
```powershell
terraform state rm docker_container.orfao
docker ps --filter "name=orfao"
```
O container `orfao` continua vivo — `state rm` tira do state **sem destruir** o
recurso real. Pense em quando isso ajuda (migrar um recurso entre configs
distintas) e quando é perigoso (esquecer que ele existe e continuar "pagando"
por ele sem o Terraform gerenciar).

## Limpeza
```powershell
docker rm -f orfao
terraform destroy -auto-approve
```

## Critério de conclusão
Você fez um `import`, chegou a plan vazio, e sabe explicar a diferença entre
`state rm` e `destroy` sem pensar.

## Notas
