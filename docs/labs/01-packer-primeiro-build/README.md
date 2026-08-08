# Packer Lab 1 — primeiro build

**~1h**

## Objetivo
Um `.pkr.hcl` mínimo que produz uma imagem Docker local.

## Teoria

**O problema que o Packer resolve.** Você precisa de um servidor com nginx,
patches em dia e o agente de monitoração instalado. O jeito manual: sobe uma
máquina, instala tudo na mão, e repete isso a cada máquina nova. O resultado
é conhecido — nenhuma máquina fica exatamente igual à outra ("mas na minha
funciona"), e ninguém sabe ao certo o que tem dentro de cada uma.

O Packer inverte isso: **a imagem é construída uma vez, por código, e vira o
artefato**. Toda máquina nova nasce dela, idêntica. Não se configura servidor
depois de criado — se constrói a imagem certa antes. É o princípio de
**infraestrutura imutável**: em vez de consertar o que está rodando, você
substitui por uma versão nova da imagem.

**Por que Docker nos primeiros labs.** O Packer não é uma ferramenta de
Docker — ele constrói AMI na AWS, Managed Image no Azure, VHDX no Hyper-V,
OVA no VMware. O que muda entre esses casos é o **builder** (o bloco
`source`); a estrutura do arquivo é a mesma. Começar com Docker é escolha
prática: o build leva segundos em vez de minutos, e você itera rápido
enquanto aprende a estrutura. Quando trocarmos para Hyper-V no Bloco 4, o
arquivo terá o mesmo formato — só o `source` muda.

**Plugins e o `packer init`.** O Packer, sozinho, não sabe falar com Docker,
AWS ou Hyper-V. Cada integração dessas é um **plugin** — um binário separado,
baixado sob demanda. O bloco `required_plugins` declara de quais você precisa
e em que versão; `packer init` lê essa declaração e baixa. É o mesmo modelo do
`terraform init` com providers, e existe pela mesma razão: manter o binário
principal pequeno e as integrações versionadas de forma independente.

**O ciclo de trabalho** é sempre o mesmo, e vale memorizar:

```text
packer init      → baixa os plugins declarados
packer validate  → confere sintaxe e configuração, sem construir nada
packer build     → constrói de verdade
```

## O que vamos criar

Um arquivo só: `packer/templates/ubuntu-base.pkr.hcl` — nomeado pelo
**artefato que produz**, não pelo número do lab. É a convenção do repo
(ver [README raiz](../../../README.md)), e a razão é prática: daqui a seis
meses `ubuntu-base` diz o que o arquivo faz, `lab01` não diz nada.

Ele tem três blocos, cada um com um papel:

- **`packer {}`** declara **com o quê** falar (o plugin). Sem isso o
  `packer init` não sabe o que baixar.
- **`source {}`** declara **de onde partir** — a base e como tratá-la.
  `commit = true` faz o Packer commitar o container final como imagem, em vez
  de descartá-lo.
- **`build {}`** amarra: pega o(s) source(s) e roda os passos. Sem
  `provisioner`, é o build mínimo possível — sobe e commita.

## Passo 1 — criar o template

Um script, cria tudo. Rode da raiz `labs/`:

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

Write-RepoFile "packer/templates/ubuntu-base.pkr.hcl" @'
# Imagem base Ubuntu — sem provisionamento, só a base commitada.
# Piso das demais imagens e smoke test do toolchain.
#
# Paths relativos aqui dentro são resolvidos a partir de packer/,
# que é o diretório onde o Taskfile invoca o packer.

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
'@
```

## Passo 2 — rodar

Da raiz `labs/`, sem `cd`:

```powershell
task packer:validate IMAGE=ubuntu-base
task packer:build    IMAGE=ubuntu-base
docker image ls --all --filter "dangling=true"
```

> Repare: `docker images` "normal" **não** mostra a imagem nova. O template
> ainda não dá nome/tag a ela (isso é o `post-processor "docker-tag"` do
> Lab 03) — sem tag, o Docker marca como `<untagged>`, e só aparece com
> `--all`. A imagem existe e é válida, só não tem nome ainda. Imagem sem tag
> é inútil em produção; é exatamente esse buraco que o Lab 03 fecha.

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

## Limpeza

A imagem sem tag fica ocupando espaço. Quando não precisar mais dela:

```powershell
task clean
```

## Notas

- **`commit = true` em uma frase:** faz o Packer rodar `docker commit` no
  container ao final do build, transformando o estado dele numa imagem nova —
  sem isso, o container seria só descartado quando o Packer termina.
- **A imagem sem tag me confundiu no começo.** Depois do primeiro `packer build`,
  `docker images` não mostrava nada — parecia que tinha falhado. Só apareceu com
  `docker image ls --all --filter "dangling=true"`, como `<untagged>`. A imagem
  estava lá o tempo todo; só não tinha nome ainda (isso só se resolve no Lab 03,
  com o `post-processor "docker-tag"`).
- **O "Quebre isto" não quebrou na primeira tentativa.** Comentar o bloco
  `packer {}` não bastou — o build continuou funcionando, porque o Packer também
  acha o plugin já instalado no disco, independente do `required_plugins`
  declarado. Só vi o erro real (`unknown by Packer`) isolando o
  `PACKER_PLUGIN_PATH` numa pasta vazia. Isso mudou como eu entendo o que o
  `packer init` realmente faz: ele resolve o plugin pra baixar, mas depois de
  baixado uma vez, o Packer não depende mais do bloco declarado pra achá-lo.
