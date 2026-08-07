# Terraform Lab 6 — state na prática

**~1h · o que separa júnior de sênior**

## Objetivo
Operar o state com confiança. É o lab mais denso do bloco — reserve a sessão longa.

## Onde o código mora
`terraform/stacks/web-state/main.tf`.

> **Conexão com o objetivo:** com N tenants, o state fica separado por tenant
> ou por stack? O que acontece com os outros se o state de um corromper?

## Base

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

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-state init
terraform -chdir=terraform/stacks/web-state apply -auto-approve
```

## Parte 1 — inspeção

```powershell
terraform -chdir=terraform/stacks/web-state state list
terraform -chdir=terraform/stacks/web-state state show docker_container.app
```

## Parte 2 — import

1. Crie um container **fora** do Terraform:

   ```powershell
   docker run -d --name orfao -p 9090:80 nginx
   ```

2. Adicione o bloco correspondente a `terraform/stacks/web-state/main.tf`
   (só declare, **não** rode `apply`):

   ```hcl
   resource "docker_container" "orfao" {
     name  = "orfao"
     image = docker_image.nginx.image_id
   }
   ```

3. Importe:

   ```powershell
   $cid = docker inspect -f '{{.Id}}' orfao
   terraform -chdir=terraform/stacks/web-state import docker_container.orfao $cid
   ```

4. `terraform -chdir=terraform/stacks/web-state plan` — vai mostrar
   diferenças (portas, labels, etc. que você não declarou). Ajuste a config
   até o plan ficar **vazio**. Esse ajuste é o exercício real: você está
   descobrindo o estado verdadeiro do recurso a partir do que já existe —
   não confie na primeira config que você escreveu de cabeça, confie no que
   o `plan` te mostra depois do import.

> Alternativa moderna (Terraform ≥ 1.5): bloco
> `import { to = docker_container.orfao, id = "..." }` no código, seguido de
> `terraform plan -generate-config-out=gerado.tf`, que já escreve a config
> para você. Vale testar as duas formas.

## Parte 3 — drift

```powershell
docker stop orfao
terraform -chdir=terraform/stacks/web-state plan
```

O Terraform detecta que o container não está mais rodando e propõe corrigir.
Agora compare com:

```powershell
terraform -chdir=terraform/stacks/web-state plan -refresh-only
```

Aqui ele só reconcilia o **state** com a realidade (mostra o que mudou), sem
propor nenhuma ação para mudar a realidade de volta.

## Parte 4 — mv e moved

1. Renomeie `docker_container.app` para `docker_container.web` no `main.tf`.
2. `terraform -chdir=terraform/stacks/web-state plan` → ele quer **destruir e
   criar**. Não aplique.
3. Resolva de duas formas (desfaça uma antes de testar a outra):
   - Imperativo:
     `terraform -chdir=terraform/stacks/web-state state mv docker_container.app docker_container.web`
   - Declarativo (prefira este — fica registrado no código, versionado):

     ```hcl
     moved {
       from = docker_container.app
       to   = docker_container.web
     }
     ```

4. `terraform -chdir=terraform/stacks/web-state plan` de novo — deve ficar vazio.

## Parte 5 — rm

```powershell
terraform -chdir=terraform/stacks/web-state state rm docker_container.orfao
docker ps --filter "name=orfao"
```

O container `orfao` continua vivo — `state rm` tira do state **sem destruir** o
recurso real. Pense em quando isso ajuda (migrar um recurso entre configs
distintas) e quando é perigoso (esquecer que ele existe e continuar "pagando"
por ele sem o Terraform gerenciar).

## Critério de conclusão
Você fez um `import`, chegou a plan vazio, e sabe explicar a diferença entre
`state rm` e `destroy` sem pensar.

## Limpeza

```powershell
docker rm -f orfao
terraform -chdir=terraform/stacks/web-state destroy -auto-approve
```

## Notas

- **Parte 1 (inspeção):** `state list` mostrou `docker_container.app` e
  `docker_image.nginx`. `state show docker_container.app` revelou o snapshot
  completo do recurso no state (id, hostname, network_data, etc.).
- **Parte 2 (import):** container `orfao` criado fora do Terraform e
  importado com sucesso via `terraform import docker_container.orfao $cid`.
  Config ajustada (portas, `start`, `must_run`, etc.) até o plan ficar vazio
  — o `image` importado veio como a tag literal (`nginx`), não o SHA que
  `docker_image.nginx.image_id` resolve, então bater os dois foi parte do
  ajuste.
- **Parte 3 (drift):** `docker stop orfao` causou drift detectado pelo plan
  (queria recriar). `plan -refresh-only` mostrou apenas as mudanças sem
  propor correção — útil para auditoria sem risco de aplicar nada.
- **Parte 4 (moved):** renomear `docker_container.app` para
  `docker_container.web` sem tratamento causou destroy/create. Bloco
  `moved { from = docker_container.app, to = docker_container.web }`
  resolveu — plan ficou vazio, renomeando sem destruir.
- **Parte 5 (state rm):** `terraform state rm docker_container.orfao` removeu
  do state, mas o container continuou rodando (`docker ps` confirmou).
  Diferença clara: `state rm` tira do controle, `destroy` destrói o recurso
  real.
- **Limpeza confirmada de verdade:** ao final, nenhum container `lab11-*` ou
  `orfao` restou no Docker, e o `terraform.tfstate` do stack ficou com 0
  recursos gerenciados — o `moved {}` block continua no `main.tf` (registro
  do rename), mas a declaração de `orfao` foi removida depois do `state rm`.
