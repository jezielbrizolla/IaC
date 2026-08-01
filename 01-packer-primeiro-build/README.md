# Packer Lab 1 — primeiro build

**~1h**

## Objetivo
Um `.pkr.hcl` mínimo que produz uma imagem Docker local.

## O que escrever
- Bloco `packer { required_plugins { docker = { source = "github.com/hashicorp/docker", version = "~> 1" } } }`
- `source "docker" "ubuntu"` com `image` e `commit = true`
- `build` referenciando `source.docker.ubuntu`

## Rodar
```
packer init .
packer fmt .
packer validate .
packer build .
docker images     # a imagem nova deve aparecer
```

## Quebre isto
Apague o bloco `required_plugins` e rode `packer build` de novo. Leia o erro.
É assim que você entende para que serve o `packer init` — sem ele, o Packer não sabe
de onde baixar o plugin do builder.

## Critério de conclusão
`docker images` mostra a imagem, e você sabe explicar em uma frase o que `commit = true` faz.

## Notas
