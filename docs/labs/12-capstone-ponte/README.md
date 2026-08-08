# Capstone Lab 1 — a ponte Packer → Terraform

**~1h**

## Objetivo
Packer produz a imagem, Terraform consome. Pipeline de duas etapas ponta a ponta.

## Teoria

**Este lab é o encontro dos dois blocos anteriores.** Até aqui, Packer e
Terraform viveram separados: um construía imagens, o outro provisionava
infra. Agora eles se conectam — e o ponto de conexão é um arquivo.

**O problema do handoff.** O Packer terminou e produziu uma imagem com um ID
específico. O Terraform precisa subir um container com **aquela** imagem. Como
o segundo descobre o que o primeiro fez?

As respostas ruins, que aparecem em pipeline real:

| Abordagem | Por que falha |
|---|---|
| Copiar o ID e colar no `.tf` | manual, esquece, fica desatualizado |
| Usar sempre `:latest` | não é reproduzível — "latest" muda embaixo de você |
| Script fazendo `sed` no `.tf` | código gerado por regex, frágil e ilegível |

**A resposta certa: o manifest como contrato.** O Packer escreve
`manifest.json` (Lab 05); o Terraform lê com `data "local_file"` +
`jsondecode()`. O ID nunca é digitado por humano nenhum.

**`data` vs `resource` — a distinção que este lab introduz.** Até agora você
só usou `resource`: coisas que o Terraform **cria e gerencia**. Um `data
source` é o oposto — algo que o Terraform apenas **lê**, sem possuir. Ele não
aparece no plan como "will be created"; é consultado antes.

Consequência prática: se o arquivo não existir, o `data` falha **antes** de
qualquer recurso ser avaliado. É o que o "Quebre isto" demonstra.

**Por que isto se chama pipeline de duas etapas.** As duas ferramentas não
rodam juntas nem se conhecem — cada uma roda no seu momento:

```text
etapa 1: packer build   →  imagem + manifest.json
                                    ↓ (o contrato)
etapa 2: terraform apply ←  lê o manifest, sobe aquela imagem
```

Num CI real, essas etapas são **jobs separados**, possivelmente em máquinas
diferentes. Aí o `manifest.json` precisa ser um artefato passado adiante — é
por isso que a pergunta do "Quebre isto" (o que garante que o arquivo existe?)
não é acadêmica.

**O que muda na nuvem:** nada de conceito. Na AWS, o Packer taggeia a AMI e o
Terraform acha ela com `data "aws_ami"` filtrando por tag. Mesmo padrão — o
build deixa um rastro, o provisionamento consome. Só o mecanismo muda.

## O que vamos criar

| Arquivo | Papel |
|---|---|
| `packer/files/capstone/default.conf` | o conteúdo servido (muda de `v1` pra `v2` no teste) |
| `packer/templates/capstone-nginx.pkr.hcl` | o template (reaproveita `packer/scripts/install-nginx.sh` do Lab 02) |
| `terraform/stacks/capstone-ponte/main.tf` | consome `packer/manifest.json` |

## Passo 1 — criar os arquivos

Rode da raiz `labs/`:

```powershell
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). `Set-Content -Encoding UTF8` no PowerShell 5.1 grava
# UTF-8 *com BOM*, e o BOM faz o `fmt -check` do CI falhar.
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

Write-RepoFile "packer/files/capstone/default.conf" @'
server {
    listen 80;
    server_name _;

    location / {
        default_type text/plain;
        return 200 'capstone v1\n';
    }
}
'@

Write-RepoFile "packer/templates/capstone-nginx.pkr.hcl" @'
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
'@

Write-RepoFile "terraform/stacks/capstone-ponte/main.tf" @'
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
'@
```

> `default_type`, não `add_header Content-Type` — `add_header` **acrescenta**
> um header, não substitui. Com `return`, o corpo já tem um Content-Type
> padrão (`application/octet-stream`); `add_header` viraria
> `"application/octet-stream,text/plain"`, e o cliente trataria a resposta
> como binário. Mesmo cuidado já registrado em `packer/files/nginx/default.conf`.

## Passo 2 — rodar o pipeline

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

## Próximos passos: multi-cloud

Este pipeline (Packer builda → manifest → Terraform consome) é o padrão
inteiro que se repete trocando só o provider. O próximo track do repo — ver
[`docs/PROXIMO-TRACK.md`](../PROXIMO-TRACK.md) — generaliza exatamente isto
para AWS, Azure e Oracle Cloud (OCI): `source "docker"` vira `amazon-ebs` /
`azure-arm` / `oci-...`, o `docker_container` vira `aws_instance` /
`azurerm_linux_virtual_machine` / o equivalente OCI, e o `manifest.json` como
ponte Packer→Terraform não muda de conceito — só de conteúdo.

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
