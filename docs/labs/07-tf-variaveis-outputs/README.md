# Terraform Lab 2 — variáveis, tipos e outputs

**~1h**

## Objetivo
Parametrizar a stack e expor informação de volta.

## Onde o código mora
`terraform/stacks/web-basic/` — **o mesmo stack do Lab 06**, agora expandido.

Isso é proposital: em vez de criar um diretório por aula, o stack evolui. Você
sai de tudo hardcoded (`lab06-web`, `8080`) para entrada parametrizável — que é
o primeiro passo concreto na direção de "um tenant = uma chamada com valores
diferentes".

Arquivos ao final:
```
terraform/stacks/web-basic/
├── main.tf              ← modificado
├── variables.tf         ← novo
├── outputs.tf           ← novo
└── terraform.tfvars     ← novo
```

> Separar em `variables.tf` / `outputs.tf` / `main.tf` é convenção, não regra —
> o Terraform lê todos os `.tf` do diretório como se fossem um arquivo só. A
> convenção existe pra quem lê o código encontrar a interface (entradas e
> saídas) sem caçar dentro da lógica.

## `variables.tf`
```hcl
variable "container_name" {
  type    = string
  default = "web"
}

variable "external_port" {
  type = number

  validation {
    condition     = var.external_port >= 1024 && var.external_port <= 65535
    error_message = "external_port precisa estar entre 1024 e 65535 (portas < 1024 exigem privilégio root)."
  }
}

variable "labels" {
  type = map(string)
  default = {
    ambiente = "lab"
  }
}
```

Três tipos diferentes de propósito:
- `container_name` — `string` com `default`, o caso simples
- `external_port` — `number` **sem** `default`, então é **obrigatória**, e com
  bloco `validation` que roda antes de qualquer recurso ser tocado
- `labels` — `map(string)`, mostrando tipo composto

## `main.tf` (modificar o do Lab 06)
```hcl
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
```

O `locals` compõe `"web"` + `"lab"` → `web-lab`. Só mudaram duas linhas do Lab
06: o `name` (agora `local.full_name`) e o `external` (agora `var.external_port`).

## `outputs.tf`
```hcl
output "url" {
  value = "http://localhost:${var.external_port}"
}

output "container_id" {
  value = docker_container.web.id
}
```

`output` é a **saída** do stack — o que o próximo estágio consome. Repare que
`url` é derivado de variável (existe antes do apply) e `container_id` vem de um
atributo do recurso (só existe depois). No Lab 10 os outputs viram a interface
pública do módulo.

## `terraform.tfvars`
```hcl
external_port = 8081
```

Arquivo lido **automaticamente** pelo Terraform, sem precisar de `-var-file`.

## Rodar — as quatro formas de passar valor

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

A quarta forma é o `default` — que aqui não se aplica a `external_port` (ela não
tem default, é obrigatória), mas se aplica a `container_name` e `labels`.

**Precedência real** (⚠ diferente do Packer do Lab 03 — não é só trocar o
prefixo, a ordem entre tfvars e env var **inverte**):
```
default  <  TF_VAR_*  <  terraform.tfvars  <  -var
```
`terraform.tfvars` vence variável de ambiente. Testado isolado: com
`external_port` só no `terraform.tfvars` (8081) e `TF_VAR_external_port=8083`
setado por cima, o resultado é **8081** — o ambiente perde. É por isso que o
passo 3 acima precisa tirar o `terraform.tfvars` do caminho antes de testar o
env var; sem isso, o `apply` sempre volta pro valor do arquivo, mascarando a
variável de ambiente por completo.

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
```
Error: Invalid value for variable
  on variables.tf line 6:
   6: variable "external_port" {
    ├────────────────
    │ var.external_port is 80

external_port precisa estar entre 1024 e 65535 (portas < 1024 exigem
privilégio root).
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

Depois, reescreva a `error_message` de um jeito que **você mesmo** entenderia
daqui a 6 meses, sem contexto.

## Entenda
`variable` = entrada, vem de fora. `locals` = valor derivado, calculado dentro.
Se você tem uma `variable` com `default` que ninguém nunca sobrescreve,
provavelmente era `locals`.

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
