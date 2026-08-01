# Packer Lab 1 — primeiro build

**~1h**

## Objetivo
Um `.pkr.hcl` mínimo que produz uma imagem Docker local.

## Arquivos a criar
`docker.pkr.hcl`:
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
  name    = "primeiro-build"
  sources = ["source.docker.ubuntu"]
}
```

## Rodar
```powershell
cd labs\01-packer-primeiro-build
packer init .
packer fmt .
packer validate .
packer build .
docker images | Select-String "ubuntu"
```

## Quebre isto
1. Comente ou apague o bloco `required_plugins` inteiro.
2. Apague o cache de plugins para forçar o erro real: `Remove-Item -Recurse -Force "$env:APPDATA\packer.d\plugins"` (se existir).
3. `packer build .` — leia o erro. É assim que você entende para que serve o `packer init`:
   sem ele (e sem o plugin já baixado), o Packer não sabe como falar com o Docker.
4. Recoloque o bloco e rode `packer init .` de novo antes de seguir.

## Critério de conclusão
`docker images` mostra a imagem nova, e você sabe explicar em uma frase o que `commit = true` faz
(commita o container final como uma imagem, em vez de descartá-lo).

## Notas
