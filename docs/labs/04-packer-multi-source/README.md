# Packer Lab 4 — múltiplos sources e post-processors

**~1h**

## Objetivo
Um único `build` produzindo duas imagens com os mesmos passos.

## Teoria

**O conceito que sustenta multi-cloud.** Até aqui, cada template tinha um
`source` — uma base, uma imagem de saída. Mas o caso real é: você precisa da
*mesma* imagem na AWS e no Azure. Ou da mesma stack sobre Ubuntu e sobre
Alpine. A alternativa ruim é copiar o template e manter duas cópias em
sincronia (elas divergem na terceira semana).

O Packer resolve com **um `build` apontando para vários `source`**. Os passos
de provisionamento são declarados uma vez; o Packer roda cada source
independentemente, produzindo N artefatos.

**Os builds rodam em paralelo e são independentes.** Isso tem consequência
prática: se um source falhar, os outros continuam e podem terminar com
sucesso. Você pode acabar com um artefato bom e um build vermelho — vale
saber disso antes de confiar num pipeline que builda vários alvos.

**`only` e `except` — provisionamento condicional.** Nem todo passo serve
para todo source. Instalar `curl` no Ubuntu é `apt-get`; no Alpine é `apk`.
Rodar o comando errado quebra. Por isso o provisioner aceita:

- **`only = ["docker.ubuntu"]`** — roda *apenas* nesse source
- **`except = [...]`** — roda em todos, *menos* nesses

A referência é `tipo.nome` (`docker.ubuntu`), não só o nome.

**`${source.name}` — como um post-processor vira N resultados diferentes.**
O `post-processor "docker-tag"` é declarado uma vez, mas roda uma vez por
source. Dentro dele, `${source.name}` resolve para o nome do source que
gerou *aquele* artefato — `"ubuntu"` ou `"alpine"`. É assim que uma
declaração só produz `multi-base:ubuntu` e `multi-base:alpine`.

> Cuidado: `${build.name}` **não** é a mesma coisa, e foi o erro cometido no
> primeiro rascunho deste lab. Ver Notas.

**Por que isto importa mais do que parece.** Este é exatamente o padrão de
"mesma imagem para AWS e Azure": um `build`, dois `source` (`amazon-ebs` +
`azure-arm`), mesmos provisioners condicionados por `only`/`except`. Você
está aprendendo aqui, com Docker em segundos, a estrutura que vai reusar na
nuvem — só o `source` muda.

## O que vamos criar

`packer/templates/multi-base.pkr.hcl` — nomeado pelo que produz: a mesma
instalação em duas bases diferentes.

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

Write-RepoFile "packer/templates/multi-base.pkr.hcl" @'
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
'@
```

## Passo 2 — rodar

```powershell
task packer:build IMAGE=multi-base
docker images multi-base
```

Deve aparecer `multi-base:ubuntu` e `multi-base:alpine`, produzidas por um
único comando. Repare no output: as linhas `docker.ubuntu` e `docker.alpine`
vêm **intercaladas** — é o paralelismo acontecendo.

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

> **Ao desfazer, confira o arquivo inteiro.** Restaurar bloco comentado é
> fácil de fazer errado — a linha `provisioner "shell" {` pode sumir junto
> com o comentário, deixando `only`/`inline` soltos dentro do `build{}`.
> O `packer validate` não pega isso tão claramente quanto você esperaria.
> Ver Notas.

## Critério de conclusão
`docker images multi-base` mostra as duas tags, produzidas por um
`task packer:build` só.

## Limpeza

```powershell
docker rmi multi-base:ubuntu multi-base:alpine
task clean
```

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
