# Terraform Lab 2 — variáveis, tipos e outputs

**~1h**

## Objetivo
Parametrizar a stack e expor informação de volta.

## Teoria

**Entrada e saída — a interface do stack.** No Lab 06 tudo estava cravado:
`lab06-web`, porta `8080`. Um stack assim serve pra uma coisa só. Este lab
transforma ele numa **unidade parametrizável**, que é o primeiro passo
concreto na direção de "um tenant = uma chamada com valores diferentes".

- **`variable`** = a entrada. O que quem usa o stack decide.
- **`output`** = a saída. O que o stack devolve pra quem chamou — ou pro
  próximo estágio do pipeline.
- **`locals`** = valor derivado, calculado dentro. Mesmo conceito do Lab 03.

**Tipos e validação acontecem antes de tocar em nada.** `type = number` faz o
Terraform recusar uma string. E o bloco `validation` permite regra própria —
que roda **antes** de qualquer recurso ser criado ou modificado. É a diferença
entre falhar em 2 segundos com uma mensagem clara e falhar em 2 minutos com um
erro do provider.

**Variável sem `default` é obrigatória.** Com `default`, é opcional. Essa é a
única diferença — não existe palavra-chave `required`.

**A precedência — e o aviso mais importante deste lab.** O Terraform aceita o
mesmo valor por quatro caminhos, e a ordem é:

```text
default  <  TF_VAR_*  <  terraform.tfvars  <  -var
```

> ⚠️ **Isto é diferente do Packer (Lab 03)**, onde a ordem é
> `default < PKR_VAR_* < -var-file < -var`. No Packer a variável de ambiente
> perde pro arquivo passado por `-var-file`; no Terraform, o
> `terraform.tfvars` (que é lido **automaticamente**, sem flag) vence a
> variável de ambiente.
>
> Não assuma simetria entre as duas ferramentas. Esta ordem foi **verificada
> rodando**, não lida na documentação — e a primeira versão deste README
> documentava errado. Ver Notas.

Consequência prática: se existe um `terraform.tfvars` no diretório, exportar
`TF_VAR_alguma_coisa` **não vai funcionar** e você vai perder tempo achando
que o shell está quebrado. É preciso tirar o arquivo do caminho pra testar a
variável de ambiente.

**`output` derivado de `variable` vs de atributo de recurso.** Parece detalhe,
mas não é: `"http://localhost:${var.external_port}"` existe *antes* do apply
(vem do que você pediu). Já `docker_container.web.id` só existe *depois* (vem
do que foi criado de verdade). O primeiro pode mentir se a variável mudar sem
um apply correspondente — aconteceu neste lab, ver Notas.

**Por que separar em três arquivos.** O Terraform lê **todos** os `.tf` do
diretório como se fossem um só — `variables.tf`, `outputs.tf` e `main.tf` é
convenção, não regra. A convenção existe pra quem lê o código encontrar a
interface (entradas e saídas) sem caçar dentro da lógica.

## O que vamos criar

Este lab **expande o mesmo stack do Lab 06** — `terraform/stacks/web-basic/`.
Não cria diretório novo. Isso é proposital: em vez de uma pasta por aula, o
stack evolui.

```text
terraform/stacks/web-basic/
├── main.tf              ← modificado (locals + variáveis)
├── variables.tf         ← novo
├── outputs.tf           ← novo
└── terraform.tfvars     ← novo
```

Três variáveis, cada uma mostrando uma coisa diferente:

- `container_name` — `string` com `default`, o caso simples
- `external_port` — `number` **sem** `default` (portanto obrigatória), e com
  bloco `validation`
- `labels` — `map(string)`, mostrando tipo composto

## Passo 1 — criar os arquivos

Rode da raiz `labs/`:

```powershell
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). `Set-Content -Encoding UTF8` no PowerShell 5.1 grava
# UTF-8 *com BOM*, e o BOM faz o `terraform fmt -check` do CI falhar.
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

Write-RepoFile "terraform/stacks/web-basic/variables.tf" @'
variable "container_name" {
  type    = string
  default = "web"
}

variable "external_port" {
  type = number

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "A porta externa deve estar entre 1024 e 65535. Portas abaixo de 1024 sao reservadas para o sistema (exigem privilegio de root)."
  }
}

variable "labels" {
  type = map(string)
  default = {
    ambiente = "lab"
  }
}
'@

Write-RepoFile "terraform/stacks/web-basic/outputs.tf" @'
output "url" {
  value = "http://localhost:${var.external_port}"
}

output "container_id" {
  value = docker_container.web.id
}
'@

Write-RepoFile "terraform/stacks/web-basic/terraform.tfvars" @'
external_port = 8081
'@

# main.tf: só mudam duas linhas em relação ao Lab 06 — o `name` (agora
# local.full_name) e o `external` (agora var.external_port).
Write-RepoFile "terraform/stacks/web-basic/main.tf" @'
terraform {
  required_version = ">= 1.5"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

locals {
  full_name = "${var.container_name}-${var.labels["ambiente"]}"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = local.full_name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }
}
'@
```

> **Repare que a `error_message` não tem acento.** É deliberado: mensagem de
> erro é feita pra ser lida por humano em qualquer terminal, e acento em
> arquivo gravado por PowerShell é uma fonte real de mojibake — ver Notas.
> O `locals` compõe `"web"` + `"lab"` → `web-lab`.

## Passo 2 — rodar as quatro formas de passar valor

Da raiz `labs/`:

```powershell
terraform -chdir=terraform/stacks/web-basic init

# 1. terraform.tfvars (automático) → 8081
terraform -chdir=terraform/stacks/web-basic apply -auto-approve
terraform -chdir=terraform/stacks/web-basic output

# 2. -var (sobrescreve o tfvars) → 8082
terraform -chdir=terraform/stacks/web-basic apply -auto-approve -var="external_port=8082"

# 3. variável de ambiente — só vence se NÃO houver terraform.tfvars no caminho
Rename-Item terraform/stacks/web-basic/terraform.tfvars terraform.tfvars.bak
$env:TF_VAR_external_port = "8083"
terraform -chdir=terraform/stacks/web-basic apply -auto-approve
Remove-Item Env:\TF_VAR_external_port
Rename-Item terraform/stacks/web-basic/terraform.tfvars.bak terraform.tfvars
```

A quarta forma é o `default` — que aqui não se aplica a `external_port` (ela
não tem default, é obrigatória), mas se aplica a `container_name` e `labels`.

> **O que esperar no primeiro apply:** o Lab 06 criou o container como
> `lab06-web`. Agora o nome vira `web-lab`, e nome de container Docker não muda
> no lugar — o plan vai mostrar **destroy + create**, não update. Isso é normal
> e é uma lição: alguns atributos forçam substituição do recurso. O plan sempre
> te diz qual (`# forces replacement`).

## Quebre isto

```powershell
terraform -chdir=terraform/stacks/web-basic apply -var="external_port=80"
```

Você vai ver:

```text
Error: Invalid value for variable
  on variables.tf line 6:
   6: variable "external_port" {
    ├────────────────
    │ var.external_port is 80

A porta externa deve estar entre 1024 e 65535. ...
```

Duas coisas para observar:

1. A mensagem inclui **o valor que causou o erro** (`var.external_port is 80`) —
   por isso vale escrever `error_message` explicando o *porquê*, não só "valor
   inválido".
2. **O que aparece antes do erro depende se o recurso já existe.** Se for a
   primeira vez (`create`), o Terraform planeja parcialmente antes de abortar —
   mostra `docker_image.nginx will be created` e só depois falha na validação.
   Se o recurso já existe e a mudança seria um `replace` (como no seu caso, já
   rodando na `8083`), aparece `Planning failed` direto, sem nenhum bloco de
   recurso. Nos dois casos a validação dispara no mesmo lugar — o que muda é o
   quanto do plan já tinha sido montado antes de chegar lá.

## Critério de conclusão
`terraform output url` imprime uma URL que abre no navegador, e você testou a
precedência entre `terraform.tfvars`, `TF_VAR_*` e `-var`.

## Limpeza

```powershell
terraform -chdir=terraform/stacks/web-basic destroy -auto-approve
```

## Notas

- **`Set-Content` no Windows PowerShell 5.1 grava em ANSI por padrão, não
  UTF-8.** Passou despercebido em `main.tf`/`outputs.tf` porque não têm acento,
  mas `variables.tf` (com "privilégio" na `error_message`) saiu como
  `ISO-8859`. Funcionava local, mas quebraria num clone em Linux/CI — e é
  justamente uma mensagem de erro, feita pra ser lida por humano. Corrigido
  reescrevendo com `[System.IO.File]::WriteAllText(..., (New-Object
  System.Text.UTF8Encoding $false))`. Vale conferir `file arquivo.tf` depois de
  qualquer `Set-Content` com acento.
- **A precedência que o README original prometia estava errada, e a prova veio
  rodando de verdade.** O terceiro `apply` (com `TF_VAR_external_port=8083`)
  voltou pra `8081` em vez de ir pra `8083` — o valor do `terraform.tfvars`.
  Reproduzi isolado num diretório à parte pra confirmar: com uma variável só no
  `terraform.tfvars` e a mesma variável também setada via `TF_VAR_*`, o
  `terraform.tfvars` vence sempre. A ordem real é
  `default < TF_VAR_* < terraform.tfvars < -var` — meu README dizia
  `default < tfvars < TF_VAR_* < -var`, invertendo os dois do meio. Isso NÃO é
  igual à precedência do Packer (Lab 03), que eu tinha generalizado sem
  verificar — ferramentas diferentes, regras diferentes, não dá pra assumir
  simetria.
- **A mensagem do "Quebre isto" também saiu diferente do que eu documentei** —
  não por engano, por eu ter testado só o cenário `create` isolado. Com o
  recurso já existente (`replace`, o caso normal quando você já rodou o lab uma
  vez), o Terraform mostra `Planning failed` direto, sem o bloco parcial de
  recurso que eu tinha visto no teste isolado de criação.
- **`privilégio` apareceu como `privilÃ©gio` no terminal** — mojibake de
  exibição, não do arquivo (já confirmamos que está em UTF-8 correto). É o
  `[Console]::OutputEncoding` do PowerShell não estar em UTF-8. Não afeta o
  Terraform nem o arquivo, só a leitura visual no console.
- **Achado não planejado no `destroy` final: `output "url"` mentiu sobre a
  porta real.** O plano de destroy mostrou `url = "http://localhost:8081" ->
  null` nos outputs, mas o bloco do recurso, logo acima, mostrava
  `external = 8083 -> null` — o container real estava na `8083` (última porta
  aplicada, via env var). Aconteceu porque restauramos o `terraform.tfvars`
  (que tem `8081`) depois daquele apply, sem rodar `apply` de novo — e
  `output "url"` é `"http://localhost:${var.external_port}"`, derivado da
  **variável**, não do atributo real do recurso. A variável mudou (porque o
  arquivo mudou), o output "mudou" junto, mas o container continuava na porta
  antiga. Lição: output derivado de `variable` pode divergir do estado real se
  a variável mudar sem um `apply` correspondente; um output confiável viria do
  atributo do recurso, não do que foi pedido a ele.
- **A `error_message` foi reescrita sem acentos**, de propósito — o README
  original mostrava uma versão com "privilégio" que não bate mais com o
  arquivo real. Sincronizado no retrofit de 2026-08-08.
