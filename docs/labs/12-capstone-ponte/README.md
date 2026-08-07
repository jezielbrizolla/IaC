# Capstone Lab 1 — a ponte Packer → Terraform

**~1h**

## Objetivo
Packer produz a imagem, Terraform consome. Pipeline de duas etapas ponta a ponta.

## Onde o código mora

- `packer/templates/capstone-nginx.pkr.hcl` — o template (reaproveita
  `packer/scripts/install-nginx.sh`, já usado no Lab 02)
- `packer/files/capstone/default.conf` — o conteúdo servido (o que muda
  entre `v1` e `v2` no teste do fim)
- `terraform/stacks/capstone-ponte/main.tf` — consome `packer/manifest.json`

## Arquivos

`packer/files/capstone/default.conf`:

```nginx
server {
    listen 80;
    server_name _;

    location / {
        default_type text/plain;
        return 200 'capstone v1\n';
    }
}
```

> `default_type`, não `add_header Content-Type` — `add_header` **acrescenta**
> um header, não substitui. Com `return`, o corpo já tem um Content-Type
> padrão (`application/octet-stream`); `add_header` viraria
> `"application/octet-stream,text/plain"`, e o cliente trataria a resposta
> como binário. Mesmo cuidado já registrado em `packer/files/nginx/default.conf`.

`packer/templates/capstone-nginx.pkr.hcl`:

```hcl
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

source "docker" "app" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    script = "scripts/install-nginx.sh"
  }

  provisioner "file" {
    source      = "files/capstone/default.conf"
    destination = "/etc/nginx/sites-available/default"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
```

`terraform/stacks/capstone-ponte/main.tf`:

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

data "local_file" "manifest" {
  filename = "${path.module}/../../../packer/manifest.json"
}

locals {
  manifest = jsondecode(data.local_file.manifest.content)

  # Não confie em "o último item do array" — nada garante essa ordem se o
  # manifest for tocado por outro processo, ou se um build multi-source
  # (Lab 04) escrever várias entradas de uma vez. O campo last_run_uuid no
  # topo do manifest é feito exatamente para isso: aponta qual entrada é a
  # do build mais recente, sem depender de posição.
  last_build = [
    for b in local.manifest.builds : b
    if b.packer_run_uuid == local.manifest.last_run_uuid
  ][0]

  image_id = local.last_build.artifact_id
}

resource "docker_container" "app" {
  name  = "capstone-app"
  image = local.image_id

  ports {
    internal = 80
    external = 8080
  }

  command = ["nginx", "-g", "daemon off;"]
}

output "image_id" {
  value = local.image_id
}
```

## Rodar

Da raiz `labs/`:

```powershell
task packer:build IMAGE=capstone-nginx
Get-Content packer\manifest.json

terraform -chdir=terraform/stacks/capstone-ponte init
terraform -chdir=terraform/stacks/capstone-ponte apply -auto-approve
curl http://localhost:8080
```

## O teste que prova que funcionou

1. Com o container no ar, edite `packer/files/capstone/default.conf`
   (troque `capstone v1` por `capstone v2`).
2. `task packer:build IMAGE=capstone-nginx` de novo.
3. `terraform -chdir=terraform/stacks/capstone-ponte plan` — ele deve propor
   **substituir** o container, porque `local.image_id` mudou.
4. `terraform -chdir=terraform/stacks/capstone-ponte apply -auto-approve` e
   confirme com `curl http://localhost:8080`.

Esse ciclo — rebuild da imagem gera replace da instância — é literalmente o que
acontece com AMI + Auto Scaling Group na AWS. Você acabou de fazer local, em segundos.

## Quebre isto

```powershell
Rename-Item packer\manifest.json manifest.json.bak
terraform -chdir=terraform/stacks/capstone-ponte plan
```

Leia o erro: o `data "local_file"` falha antes de qualquer outra coisa ser
avaliada. Pense em como isso se comportaria dentro de um pipeline de CI que
roda Packer e Terraform em jobs separados — o que precisaria garantir essa
ordem? Restaure o manifest (`Rename-Item packer\manifest.json.bak
packer\manifest.json`) antes de seguir.

## Critério de conclusão
Um comando de Packer + um de Terraform, e a mudança de conteúdo aparece no navegador.

## Limpeza

```powershell
terraform -chdir=terraform/stacks/capstone-ponte destroy -auto-approve
```

## Notas

- **Pipeline ponta a ponta confirmado:** `task packer:build IMAGE=capstone-nginx`
  → `terraform apply` → `curl http://localhost:8080` retornou `capstone v1`
  na primeira tentativa.
- **O teste v1 → v2 funcionou exatamente como o lab prevê:** editar
  `default.conf`, rebuildar, e o `terraform plan` detectou a mudança de
  `local.image_id` e propôs `replace` do container — não `update`. Depois do
  `apply`, `curl` confirmou `capstone v2`.
- **`last_run_uuid` provado na prática, não só validado por mim antes:** o
  `image_id` calculado bateu com o build recém-feito nas duas rodadas
  (v1 e v2), mesmo com o manifest compartilhado acumulando builds de outros
  labs — a prova de que casar por `packer_run_uuid` é robusto independente
  de quantas entradas não-relacionadas existam no arquivo.
- **Quebre isto confirmado:** renomear `manifest.json` pra `.bak` quebrou o
  `data "local_file"` antes de qualquer outra coisa ser avaliada, exatamente
  como o README descreve — Terraform falha rápido, sem chegar perto do
  `docker_container.app`. Restaurado e `destroy` limpou tudo (state final
  com 0 recursos).
