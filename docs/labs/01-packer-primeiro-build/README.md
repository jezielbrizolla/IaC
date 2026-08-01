# Packer Lab 1 — primeiro build

**~1h**

## Objetivo
Um `.pkr.hcl` mínimo que produz uma imagem Docker local.

## Onde o código mora
`packer/templates/ubuntu-base.pkr.hcl` — nomeado pelo **artefato que produz**,
não pelo número do lab. É a convenção do repo (ver [README raiz](../../../README.md)).

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

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name    = "ubuntu-base"
  sources = ["source.docker.ubuntu"]
}
```

Três blocos, cada um com um papel:
- `packer {}` declara **com o quê** falar (o plugin). Sem isso o `packer init`
  não sabe o que baixar.
- `source {}` declara **de onde partir** — a base e como tratá-la. `commit = true`
  faz o Packer commitar o container final como imagem, em vez de descartá-lo.
- `build {}` amarra: pega o(s) source(s) e roda os passos. Sem `provisioner`,
  é o build mínimo possível — sobe e commita.

## Rodar
Da raiz do repo, sem `cd`:
```powershell
task packer:validate IMAGE=ubuntu-base
task packer:build    IMAGE=ubuntu-base
docker image ls --all --filter "dangling=true"
```

> Repare: `docker images` "normal" **não** mostra a imagem nova. O template
> ainda não dá nome/tag a ela (isso é o `post-processor "docker-tag"` do
> Lab 04) — sem tag, o Docker marca como `<untagged>`, e só aparece com `--all`.
> A imagem existe e é válida, só não tem nome ainda. Imagem sem tag é inútil em
> produção; é exatamente esse buraco que o lab 04 fecha.

## Quebre isto
1. Comente o bloco `packer {}` inteiro (`/* ... */` funciona em HCL).
2. `task packer:build IMAGE=ubuntu-base` — provavelmente **ainda funciona**.
   O Packer também escaneia os plugins já instalados no disco e casa
   `source "docker"` com o binário que encontrar.
3. Para ver o erro de verdade, isole o cache de plugins:
   ```powershell
   $env:PACKER_PLUGIN_PATH = "$env:TEMP\plugins-vazio"
   task packer:build IMAGE=ubuntu-base
   Remove-Item Env:\PACKER_PLUGIN_PATH
   ```
   `The source docker is unknown by Packer` — é o que o `packer init` resolve.
4. Descomente o bloco e rode `task packer:init` antes de seguir.

## Critério de conclusão
`docker image ls --all --filter "dangling=true"` mostra a imagem nova, e você
sabe explicar em uma frase o que `commit = true` faz.

## Notas

- **`commit = true` em uma frase:** faz o Packer rodar `docker commit` no
  container ao final do build, transformando o estado dele numa imagem nova —
  sem isso, o container seria só descartado quando o Packer termina.
- **A imagem sem tag me confundiu no começo.** Depois do primeiro `packer build`,
  `docker images` não mostrava nada — parecia que tinha falhado. Só apareceu com
  `docker image ls --all --filter "dangling=true"`, como `<untagged>`. A imagem
  estava lá o tempo todo; só não tinha nome ainda (isso só se resolve no lab 04).
- **O "Quebre isto" não quebrou na primeira tentativa.** Comentar o bloco
  `packer {}` não bastou — o build continuou funcionando, porque o Packer também
  acha o plugin já instalado no disco, independente do `required_plugins`
  declarado. Só vi o erro real (`unknown by Packer`) isolando o
  `PACKER_PLUGIN_PATH` numa pasta vazia. Isso mudou como eu entendo o que o
  `packer init` realmente faz: ele resolve o plugin pra baixar, mas depois de
  baixado uma vez, o Packer não depende mais do bloco declarado pra achá-lo.
