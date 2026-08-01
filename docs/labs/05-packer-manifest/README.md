# Packer Lab 5 — golden image + manifest

**~1h · a ponte**

## Objetivo
Fazer o Packer registrar **qual** imagem ele produziu, em formato legível por máquina.

## Onde o código mora
`packer/templates/golden-manifest.pkr.hcl` — reaproveita a base do Lab 03
(`variable "app_version"`), acrescentando um segundo `post-processor`.

## O template
```hcl
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
```

Um `build` pode ter **múltiplos post-processors**, rodando em sequência — aqui,
`docker-tag` primeiro, `manifest` depois. O `manifest` não altera a imagem, só
escreve um recibo em JSON depois do build: qual imagem foi produzida, quando,
com qual builder.

## Rodar
Sempre a partir de `packer/` (os paths do template e o `manifest.json` gerado
são relativos a esse diretório):
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
```

## Depois do build
Abra `manifest.json`. Estrutura: `builds[]` (array que cresce a cada build),
cada item com `name`, `artifact_id`, `packer_run_uuid`, `custom_data`; e
`last_run_uuid` no topo, fora do array, marcando qual `packer_run_uuid`
corresponde ao build mais recente.

## Por que isto importa
Este JSON é o contrato entre Packer e Terraform. No Bloco 3
(`12-capstone-ponte`) o Terraform vai lê-lo com `jsondecode()` e subir
exatamente esta imagem. Na AWS o equivalente é o Terraform buscar a AMI com
`data "aws_ami"` filtrando por uma tag que o Packer escreveu.

## Quebre isto
Rode 3 builds seguidos (`-var "app_version=3.0"`, `4.0`, `5.0`) e, com 5
builds acumulados no manifest, decida: **como identificar "a imagem certa" —
a mais recente — só olhando esse arquivo?**

A regra correta é casar `last_run_uuid` (topo do JSON) com o
`packer_run_uuid` de cada item em `builds[]`:
```hcl
locals {
  manifest = jsondecode(file("manifest.json"))
  latest   = [for b in local.manifest.builds : b if b.packer_run_uuid == local.manifest.last_run_uuid][0]
  image_id = local.latest.artifact_id
}
```

**Por que não simplesmente `builds[length(builds)-1]`** (o último item do
array)? Porque isso funciona hoje só por comportamento implícito — o Packer
sempre *anexa* no fim, mas isso não é uma garantia documentada. Casar pelo
`last_run_uuid` é explícito: o próprio Packer diz qual é o build atual,
independente de qualquer suposição sobre ordem do array.

## Critério de conclusão
`manifest.json` existe, tem múltiplos builds, e você sabe qual expressão usar
para pegar o `artifact_id` da imagem mais recente.

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
