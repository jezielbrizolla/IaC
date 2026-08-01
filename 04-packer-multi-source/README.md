# Packer Lab 4 — múltiplos sources e post-processors

**~1h**

## Objetivo
Um único `build` produzindo duas imagens com os mesmos passos.

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

source "docker" "alpine" {
  image  = "alpine:3.20"
  commit = true
}

build {
  sources = [
    "source.docker.ubuntu",
    "source.docker.alpine",
  ]

  provisioner "shell" {
    only   = ["docker.ubuntu"]
    inline = ["apt-get update", "apt-get install -y curl"]
  }

  provisioner "shell" {
    only   = ["docker.alpine"]
    inline = ["apk add --no-cache curl"]
  }

  post-processor "docker-tag" {
    repository = "meuapp"
    tag        = ["${build.name}"]
  }
}
```

## Rodar
```powershell
cd labs\04-packer-multi-source
packer init .
packer fmt .
packer validate .
packer build .
docker images meuapp
```
Deve aparecer `meuapp:docker.ubuntu` e `meuapp:docker.alpine` (o `${build.name}`
vira o nome do source quando não há `build { name = ... }` explícito).

## Quebre isto
1. Troque os dois `provisioner "shell"` por **um único**, sem `only`/`except`,
   usando `apt-get`:
   ```hcl
   provisioner "shell" {
     inline = ["apt-get update", "apt-get install -y curl"]
   }
   ```
2. `packer build .` — o Ubuntu builda, o Alpine quebra (`apt-get` não existe no Alpine;
   é `apk`). Leia o erro completo, note em qual source ele falhou.
3. Volte para os dois provisioners separados com `only = [...]`.

## Por que isto importa
É exatamente o padrão de "mesma imagem para AWS e Azure": um `build`, dois `source`
(`amazon-ebs` + `azure-arm`), mesmos provisioners condicionados por `only`/`except`.
Você está aprendendo a estrutura que vai reusar na nuvem — só o `source` muda.

## Critério de conclusão
`docker images meuapp` mostra as duas tags, produzidas por um `packer build .` só.

## Notas
