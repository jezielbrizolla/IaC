# Packer Lab 3 — variáveis e locals

**~1h**

## Objetivo
Parametrizar a imagem base e a versão do app.

## Onde o código mora
| Arquivo | Papel |
|---|---|
| `packer/templates/app-versioned.pkr.hcl` | o template |
| `packer/vars/app-versioned.pkrvars.hcl` | valores de exemplo (`app_version = "1.1"`) |

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
    tag        = [var.app_version]
  }
}
```

Repare que este template já tagueia a imagem (`post-processor "docker-tag"`) —
diferente dos labs 01 e 02, aqui você vai ver `meuapp:1.0`, `meuapp:2.0` etc.
direto no `docker images`, sem precisar de `--all`.

## Rodar — as quatro formas de passar valor

O Taskfile builda com `IMAGE=nome`; args extras do Packer (`-var`, `-var-file`)
vão depois de `--`:

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
   ```
   Error: Unset variable "must_have"
   A used variable must be set or have a default value; ...
   ```
2. Marque-a `sensitive = true`, passe um valor com `-var "must_have=segredo123"`.
   O valor **não aparece em nenhum lugar** do output do build — nem em
   `packer inspect .`, que mostra `var.must_have: "<unknown>"` em vez do valor
   real. `sensitive` mascara nos dois.

## Critério de conclusão
`task packer:validate IMAGE=app-versioned` e `packer fmt` limpos, e o mesmo
template produz 4 imagens diferentes só mudando a forma de passar `app_version`.

## Notas
