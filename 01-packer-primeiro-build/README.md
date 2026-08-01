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
docker image ls --all --filter "dangling=true"
```
> Repare: `docker images` "normal" **não** mostra a imagem nova. O template
> ainda não dá nome/tag a ela (isso é o `post-processor "docker-tag"` do
> Lab 04) — sem tag, o Docker marca a imagem como `<untagged>`, e só aparece
> com `--all`. A imagem existe e é válida, só não tem nome ainda.

## Quebre isto
1. Comente ou apague o bloco `required_plugins` inteiro.
2. Apague o cache de plugins para forçar o erro real: `Remove-Item -Recurse -Force "$env:APPDATA\packer.d\plugins"` (se existir).
3. `packer build .` — leia o erro. É assim que você entende para que serve o `packer init`:
   sem ele (e sem o plugin já baixado), o Packer não sabe como falar com o Docker.
4. Recoloque o bloco e rode `packer init .` de novo antes de seguir.

## Critério de conclusão
`docker image ls --all --filter "dangling=true"` mostra a imagem nova (como
`<untagged>`), e você sabe explicar em uma frase o que `commit = true` faz
(commita o container final como uma imagem, em vez de descartá-lo).

## Automação
Depois de fazer o lab na mão pelo menos uma vez (é assim que se aprende),
`run.ps1` automatiza o ciclo inteiro — inclusive o "Quebre isto", reproduzido
numa cópia temporária isolada (`PACKER_PLUGIN_PATH` apontando pra uma pasta
vazia), sem tocar no seu arquivo real nem no cache de plugins de verdade:
```powershell
cd labs\01-packer-primeiro-build
.\run.ps1                    # ciclo completo, atualiza o CHECKLIST.md
.\run.ps1 -SkipBreakTest      # pula o teste de quebra, mais rápido
```
Útil pra reverificar depois de editar o `.pkr.hcl`, ou como teste de
regressão do próprio conteúdo do lab. Usa a lib compartilhada em `../_lib/`
(mesma do `00-setup/setup-automation`).

## Notas
