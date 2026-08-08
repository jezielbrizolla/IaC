# Packer Lab 5 — golden image + manifest

**~1h · a ponte**

## Objetivo
Fazer o Packer registrar **qual** imagem ele produziu, em formato legível por
máquina.

## Teoria

**O problema de entrega que ninguém antecipa.** Você construiu a imagem. Ela
existe. Agora: *como a próxima etapa descobre qual é?* O Terraform precisa
subir uma máquina com **aquela** imagem específica — não "a mais recente que
alguém achar", não o ID que alguém copiou e colou num chat. Precisa ser
programático, ou o pipeline quebra na primeira vez que dois builds rodam.

**`post-processor "manifest"` é a resposta.** Ele não altera a imagem — roda
depois do build e escreve um **recibo em JSON**: qual artefato foi produzido,
quando, por qual builder, com qual identificador único de execução.

**Post-processors rodam em sequência.** Um `build` pode ter vários; aqui,
`docker-tag` primeiro (dá nome à imagem), `manifest` depois (registra o que
foi feito). A ordem é a ordem de declaração, igual aos provisioners do
Lab 02.

**O manifest acumula, não substitui.** Cada build **anexa** uma entrada em
`builds[]`. Depois de cinco builds, o arquivo tem cinco entradas — e aí vem a
pergunta que importa:

> Como identificar "a imagem certa", a mais recente, só olhando esse arquivo?

A resposta intuitiva — pegar o último item do array — funciona *hoje*, por
comportamento implícito: o Packer sempre anexa no fim. Mas isso não é
garantia documentada, e não sobrevive a build multi-source (Lab 04), que
escreve várias entradas de uma vez.

**A regra correta:** o manifest tem, no topo e fora do array, um campo
`last_run_uuid`. Cada entrada em `builds[]` tem seu `packer_run_uuid`.
Casar os dois é explícito — o próprio Packer diz qual é o build atual:

```hcl
locals {
  manifest = jsondecode(file("manifest.json"))
  latest   = [for b in local.manifest.builds : b if b.packer_run_uuid == local.manifest.last_run_uuid][0]
  image_id = local.latest.artifact_id
}
```

**Onde isso vai dar.** Este JSON é o contrato entre Packer e Terraform. No
Lab 12 (`capstone-ponte`), o Terraform vai lê-lo com `jsondecode()` e subir
exatamente esta imagem — usando exatamente a regra acima. Na AWS o
equivalente é o Terraform buscar a AMI com `data "aws_ami"` filtrando por uma
tag que o Packer escreveu. O mecanismo muda; o conceito de "o build deixa um
rastro que o próximo estágio consome" é o mesmo.

## O que vamos criar

`packer/templates/golden-manifest.pkr.hcl` — reaproveita a base do Lab 03
(`variable "app_version"`), acrescentando um segundo `post-processor`.

## Passo 1 — criar o template

Rode da raiz `labs/`:

```powershell
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). `Set-Content -Encoding UTF8` no PowerShell 5.1 grava
# UTF-8 *com BOM*, e o BOM faz o `packer fmt -check` do CI falhar.
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

Write-RepoFile "packer/templates/golden-manifest.pkr.hcl" @'
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "app_version" {
  type    = string
  default = "1.0"
}

source "docker" "app" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = ["echo build ${var.app_version}"]
  }

  post-processor "docker-tag" {
    repository = "golden"
    tags       = [var.app_version]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
'@
```

## Passo 2 — rodar e ver o manifest acumular

> **Atenção ao diretório.** Os paths do template e o `manifest.json` gerado
> são relativos a **onde você invoca o `packer`**, não à localização do
> arquivo. Rodar de dentro de `packer/templates/` criaria um segundo
> `manifest.json` no lugar errado — aconteceu de verdade, ver Notas. O
> `task packer:build` já resolve isso (roda sempre de `packer/`), mas este
> lab usa `packer` direto pra você ver o `manifest.json` aparecer.

```powershell
cd packer
packer init templates/golden-manifest.pkr.hcl
packer build templates/golden-manifest.pkr.hcl
Get-Content manifest.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

Rode de novo com outra versão e veja o manifest **acumular**, não substituir:

```powershell
packer build -var "app_version=2.0" templates/golden-manifest.pkr.hcl
Get-Content manifest.json | ConvertFrom-Json | Select-Object -ExpandProperty builds
cd ..
```

Estrutura do arquivo: `builds[]` (array que cresce a cada build), cada item
com `name`, `artifact_id`, `packer_run_uuid`, `custom_data`; e
`last_run_uuid` no topo, **fora** do array, marcando qual `packer_run_uuid`
corresponde ao build mais recente.

## Quebre isto

Rode 3 builds seguidos (`-var "app_version=3.0"`, `4.0`, `5.0`) e, com 5
builds acumulados no manifest, responda sem consultar a Teoria: **qual
expressão pega o `artifact_id` da imagem mais recente, e por que
`builds[length(builds)-1]` não é a resposta certa?**

## Critério de conclusão
`manifest.json` existe, tem múltiplos builds, e você sabe qual expressão usar
para pegar o `artifact_id` da imagem mais recente.

## Limpeza

O `manifest.json` e o `manifest.json.lock` são artefato de build (já estão no
`.gitignore`). As imagens taguadas:

```powershell
docker images golden --format "{{.Repository}}:{{.Tag}}" | ForEach-Object { docker rmi $_ }
task clean
```

## Notas

- **Rodar de dentro de `packer/templates/` em vez de `packer/` cria um
  `manifest.json` duplicado**, num lugar diferente do padrão do repo — os
  paths do `post-processor "manifest"` são relativos a onde você invoca o
  `packer`, não ao arquivo do template. Aconteceu na prática: dois manifests
  distintos, cada um com um `packer_run_uuid` só seu, porque foram execuções
  independentes em diretórios diferentes.
- **`manifest.json.lock`** é um arquivo de lock que o post-processor cria pra
  evitar corrupção se builds em paralelo (como no Lab 04) escrevessem no
  mesmo `manifest.json` ao mesmo tempo. Fica vazio — só existe pra travar
  durante a escrita. Ele e o `manifest.json` são artefato de build, não
  código; os dois foram pro `.gitignore`.
- **A regra escolhida pra identificar a imagem mais recente:** casar
  `last_run_uuid` (topo do JSON) com o `packer_run_uuid` de cada item em
  `builds[]`, em vez de confiar na posição do array. É explícito — o Packer
  te diz qual é o build atual — em vez de depender de um comportamento
  implícito (o array sempre crescer no fim) que não é uma garantia
  documentada. Essa é a regra que o Lab 12 vai usar de verdade.
