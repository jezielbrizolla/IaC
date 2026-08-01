# Packer Lab 4 — múltiplos sources e post-processors

**~1h**

## Objetivo
Um único `build` produzindo duas imagens com os mesmos passos.

## Onde o código mora
`packer/templates/multi-base.pkr.hcl` — nomeado pelo que produz: a mesma
instalação em duas bases diferentes.

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

source "docker" "alpine" {
  image  = "alpine:3.20"
  commit = true
}

build {
  sources = [
    "source.docker.ubuntu",
    "source.docker.alpine"
  ]

  provisioner "shell" {
    only = ["docker.ubuntu"]
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y curl"
    ]
  }

  provisioner "shell" {
    only = ["docker.alpine"]
    inline = [
      "apk add --no-cache curl"
    ]
  }

  post-processor "docker-tag" {
    repository = "multi-base"
    tags       = ["${source.name}"]
  }
}
```

Dois pontos novos em relação aos labs anteriores:
- **`only`** restringe um provisioner a um source específico (`tipo.nome`).
  Sem isso, o mesmo provisioner rodaria nos dois — e quebraria, porque Ubuntu
  usa `apt-get` e Alpine usa `apk`.
- **`${source.name}`** dentro do `post-processor` resolve pro nome do source
  que gerou aquela imagem (`"ubuntu"` ou `"alpine"`) — é assim que uma única
  declaração de `tags` vira duas tags diferentes, uma por build.

## Rodar
```powershell
task packer:build IMAGE=multi-base
docker images multi-base
```
Deve aparecer `multi-base:ubuntu` e `multi-base:alpine`, produzidas por um
único comando — o Packer builda os dois sources em paralelo (repare no
output: `docker.ubuntu` e `docker.alpine` intercalados).

## Quebre isto
1. Troque os dois `provisioner "shell"` por **um único**, sem `only`/`except`,
   usando `apt-get`:
   ```hcl
   provisioner "shell" {
     inline = [
       "apt-get update",
       "DEBIAN_FRONTEND=noninteractive apt-get install -y curl"
     ]
   }
   ```
2. `task packer:build IMAGE=multi-base` — o Ubuntu builda normal, o Alpine
   falha com `/tmp/script_XXXX.sh: line 2: apt-get: not found` (exit code 127,
   `apt-get` não existe no Alpine — é `apk`). Repare que **um source falhar
   não trava o outro**: os builds são independentes, rodando em paralelo.
3. Volte para os dois provisioners separados com `only = [...]`.

## Por que isto importa
É exatamente o padrão de "mesma imagem para AWS e Azure": um `build`, dois
`source` (`amazon-ebs` + `azure-arm`), mesmos provisioners condicionados por
`only`/`except`. Você está aprendendo a estrutura que vai reusar na nuvem —
só o `source` muda.

## Critério de conclusão
`docker images multi-base` mostra as duas tags, produzidas por um
`task packer:build` só.

## Notas

- **`${source.name}` funcionou, `${build.name}` (o que eu tinha sugerido
  originalmente) nunca foi testado.** `packer validate` confirmou
  `source.name` na hora — resultado: tags limpas (`multi-base:ubuntu`,
  `multi-base:alpine`), sem o prefixo `docker.` que eu tinha previsto errado
  com `build.name`.
- **Comentário de bloco em HCL é `/* ... */`, não `/. ... ./`.** Escrevi
  `/.` e `./` por engano na primeira tentativa de comentar os provisioners
  antigos — não é sintaxe válida, e o `packer validate` teria acusado erro
  se eu tivesse rodado antes de perceber.
- **Restaurar um bloco comentado é fácil de fazer errado.** Ao apagar o
  comentário e o provisioner extra, a linha `provisioner "shell" {` que
  deveria abrir o bloco do Ubuntu sumiu junto — sobrou só `only = [...]` e
  `inline = [...]` soltos dentro do `build{}`, sem bloco pai. `packer
  validate` não pega isso como erro de sintaxe imediato do jeito que eu
  esperava — foi preciso olhar o arquivo linha por linha pra achar.
- **Um source falhando não trava o outro.** Rodando o teste de quebra, o
  Ubuntu terminou o build normal (31s) enquanto o Alpine já tinha falhado
  bem antes (9s) — os dois builds do `sources = [...]` rodam em paralelo e
  são independentes.
