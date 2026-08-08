# Packer Lab 3 — variáveis e locals

**~1h**

## Objetivo
Parametrizar a imagem base e a versão do app.

## Teoria

**O problema:** nos Labs 01 e 02, tudo estava cravado no arquivo — a imagem
base é `ubuntu:22.04`, ponto. Pra construir a mesma imagem com outra base, ou
com outra versão do app, você teria que editar o template. Isso não escala:
o template deixa de ser uma *definição* e vira um rascunho que muda toda hora.

**`variable` é a entrada; `locals` é o cálculo.** A distinção importa:

- **`variable`** é o que vem **de fora** — quem chama decide. Tem `type`
  (o Packer valida) e, opcionalmente, `default` (sem default, virou
  obrigatória).
- **`locals`** é valor **derivado**, calculado dentro do próprio template a
  partir de outras coisas. Aqui, `image_tag = "meuapp:${var.app_version}"` —
  ninguém passa isso de fora, é composto.

Regra prática: se você tem uma `variable` com `default` que ninguém nunca
sobrescreve, provavelmente ela era um `locals`.

**As quatro formas de passar valor, e quem ganha.** O Packer aceita o mesmo
valor por quatro caminhos, e a precedência é:

```text
default  <  PKR_VAR_*  <  -var-file  <  -var
```

Ou seja: o que está na linha de comando (`-var`) vence tudo. O `default` do
template é o piso — só vale se ninguém disser nada.

> ⚠️ **A precedência do Terraform é diferente** — lá o arquivo
> (`terraform.tfvars`) vence a variável de ambiente, o inverso daqui. Não
> assuma simetria entre as duas ferramentas; isso está documentado no
> Lab 07, onde foi verificado na prática.

**`sensitive = true`** marca uma variável como segredo. O Packer passa a
mascarar o valor no output do build **e** no `packer inspect`. Não é
criptografia — o valor ainda trafega em claro pra dentro da imagem; é só
proteção contra vazar em log de CI, que é onde segredo costuma escapar.

**`post-processor`** roda *depois* do build terminar, sobre o artefato
produzido. Aqui é `docker-tag`, que dá nome e tag à imagem — resolvendo
aquele problema do Lab 01, onde a imagem saía `<untagged>` e só aparecia com
`docker images --all`. A partir deste lab, `docker images meuapp` mostra o
que você construiu.

## O que vamos criar

| Arquivo | Papel |
|---|---|
| `packer/templates/app-versioned.pkr.hcl` | o template |
| `packer/vars/app-versioned.pkrvars.hcl` | valores de exemplo (`app_version = "1.1"`) |

## Passo 1 — criar os arquivos

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

Write-RepoFile "packer/templates/app-versioned.pkr.hcl" @'
packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "base_image" {
  type    = string
  default = "ubuntu:22.04"
}

variable "app_version" {
  type    = string
  default = "1.0"
}

locals {
  image_tag = "meuapp:${var.app_version}"
}

source "docker" "app" {
  image  = var.base_image
  commit = true
}

build {
  sources = ["source.docker.app"]

  provisioner "shell" {
    inline = ["echo building ${local.image_tag}"]
  }

  post-processor "docker-tag" {
    repository = "meuapp"
    tags       = [var.app_version]
  }
}
'@

Write-RepoFile "packer/vars/app-versioned.pkrvars.hcl" @'
app_version = "1.1"
'@
```

> **`tags` (plural), não `tag`.** O campo singular existiu e foi **deprecado**
> — o Packer avisa *"tag" option has been replaced with "tags"*. Use `tags`
> mesmo passando um valor só, como aqui. Ver Notas.

## Passo 2 — rodar as quatro formas de passar valor

O Taskfile builda com `IMAGE=nome`; args extras do Packer (`-var`,
`-var-file`) vão depois de `--`:

```powershell
task packer:validate IMAGE=app-versioned

# 1. default (app_version = 1.0)
task packer:build IMAGE=app-versioned

# 2. -var
task packer:build IMAGE=app-versioned -- -var "app_version=2.0"

# 3. -var-file (caminho relativo a packer/, que é onde o Taskfile roda o packer)
task packer:build IMAGE=app-versioned -- -var-file="vars/app-versioned.pkrvars.hcl"

# 4. variável de ambiente PKR_VAR_*
$env:PKR_VAR_app_version = "3.0"
task packer:build IMAGE=app-versioned
Remove-Item Env:\PKR_VAR_app_version

docker images meuapp
```

Confirme que existem `meuapp:1.0`, `meuapp:2.0`, `meuapp:1.1` e `meuapp:3.0`.

## Quebre isto

1. Numa cópia temporária do template (não edite o do repo), declare uma nova
   `variable "must_have" { type = string }` **sem** `default` e sem passar
   valor em lugar nenhum. Rode `packer build .` sobre essa cópia e leia:

   ```text
   Error: Unset variable "must_have"
   A used variable must be set or have a default value; ...
   ```

   > Cuidado com onde você cola: `variable` só existe no **nível raiz** do
   > arquivo, nunca dentro de `source{}` ou `build{}`. Colar no lugar errado
   > dá outro erro (`Blocks of type "variable" are not expected here`) e você
   > não chega a ver a lição do exercício — foi o que aconteceu aqui, ver Notas.

2. Marque-a `sensitive = true`, passe um valor com `-var "must_have=segredo123"`.
   O valor **não aparece em nenhum lugar** do output do build — nem em
   `packer inspect .`, que mostra `var.must_have: "<unknown>"` em vez do valor
   real. `sensitive` mascara nos dois.

## Critério de conclusão
`task packer:validate IMAGE=app-versioned` e `packer fmt` limpos, e o mesmo
template produz 4 imagens diferentes só mudando a forma de passar `app_version`.

## Limpeza

```powershell
docker rmi meuapp:1.0 meuapp:2.0 meuapp:1.1 meuapp:3.0
task clean
```

## Notas

- **O `post-processor "docker-tag"` do meu primeiro rascunho usava `tag`
  (singular) — deprecated.** O Packer avisou sozinho: *"tag" option has been
  replaced with "tags"*. O campo certo é `tags`, mesmo passando só um valor
  na lista (`tags = [var.app_version]`).
- **Colei o `variable "must_have"` dentro do `build{}` por engano** na hora
  de montar o teste de quebra. O erro não foi "variável obrigatória" — foi
  `Blocks of type "variable" are not expected here`, porque `variable` só
  existe no nível raiz do arquivo, nunca aninhado dentro de `source{}` ou
  `build{}`. Só depois de mover pra fora é que consegui ver o erro que o
  lab realmente queria mostrar.
- **`sensitive = true` mascara em dois lugares, não só um.** Testei passando
  um valor identificável (`segredo123`) — não apareceu no output do build
  nem no `packer inspect`, que mostrou `var.must_have: "<unknown>"` em vez
  do valor real.
- **`packer inspect` calcula o `locals` de verdade**, não só lista as
  variáveis: com os defaults, mostrou `local.image_tag: "meuapp:1.0"` — a
  interpolação `${var.app_version}` já resolvida.
- **Este README mostrava `tag` (singular) no template por anos**, contradizendo
  a própria primeira Nota acima — o arquivo real no repo sempre usou `tags`.
  Corrigido no retrofit de 2026-08-08, junto com a descoberta de que o
  arquivo real também estava fora do `packer fmt` (o que deixava o CI
  vermelho).
