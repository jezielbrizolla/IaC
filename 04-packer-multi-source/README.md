# Packer Lab 4 — múltiplos sources e post-processors

**~1h**

## Objetivo
Um único `build` produzindo duas imagens com os mesmos passos.

## O que escrever
- `source "docker" "ubuntu"` e `source "docker" "alpine"`
- Um `build` com `sources = ["source.docker.ubuntu", "source.docker.alpine"]`
- `post-processor "docker-tag"` aplicando repository/tag
- Use `source.name` para diferenciar dentro dos provisioners

## Por que isto importa
É exatamente o padrão de "mesma imagem para AWS e Azure": um build, dois sources
(`amazon-ebs` + `azure-arm`), mesmos provisioners. Você está aprendendo a estrutura
que vai reusar na nuvem — só o `source` muda.

## Quebre isto
Um `shell` provisioner com `apt-get` roda no Ubuntu mas quebra no Alpine.
Rode assim de propósito, leia o erro, e resolva com `only = [...]` ou `except = [...]`
no provisioner.

## Critério de conclusão
Duas imagens taggeadas no `docker images`, produzidas por um `packer build` só.

## Notas
