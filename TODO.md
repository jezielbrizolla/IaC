# TODO — IaC Track 0

Progresso e navegação de todos os labs, num arquivo só. Substitui os 23
`CHECKLIST.md` que existiam em `docs/labs/*/` (histórico preservado no git).

## Como usar este arquivo

**Se você está começando do zero:** siga a ordem numérica. Cada lab tem um
`README.md` próprio em [`docs/labs/`](docs/labs/) com o objetivo, o código
completo, o passo "Quebre isto" e as Notas. Este arquivo é o *tracker* — ele
diz onde você está e o que falta, não como fazer.

**Se você quer revisar um conceito específico:** use o [índice de
conceitos](#índice-de-conceitos) abaixo para achar o lab certo, e vá direto
ao `README.md` dele.

**Se você está retomando:** veja [Agora](#agora) e [Backlog](#backlog).

Comandos úteis (da raiz `labs/`):

```powershell
task status    # imprime este progresso no terminal
task setup     # prepara a máquina e marca a seção 00-setup sozinho
task           # lista tudo que dá pra fazer
```

Convenções do repo — nomes de artefato, onde o código mora, por que o
`.terraform.lock.hcl` é versionado — estão no [README raiz](README.md).

---

## Índice de conceitos

Onde cada assunto é ensinado, e qual pergunta ele responde.

### Packer

| Conceito | Lab | Responde |
|---|---|---|
| `required_plugins` / `packer init` | [01](docs/labs/01-packer-primeiro-build/) | Por que preciso rodar `init` antes? |
| `commit = true` | [01](docs/labs/01-packer-primeiro-build/) | Por que a imagem sai `<untagged>`? |
| `provisioner "shell"` / `"file"` | [02](docs/labs/02-packer-provisioners/) | Como instalo e configuro coisa dentro da imagem? |
| Ordem dos provisioners | [02](docs/labs/02-packer-provisioners/) | Por que inverter a ordem quebra o build? |
| `script` externo vs `inline` | [02](docs/labs/02-packer-provisioners/) | Quando extrair para arquivo separado? |
| `variable` / `locals` | [03](docs/labs/03-packer-variaveis/) | Como parametrizo sem editar o template? |
| Precedência de variáveis (Packer) | [03](docs/labs/03-packer-variaveis/) | `-var` vs `-var-file` vs `PKR_VAR_*` |
| `sensitive = true` | [03](docs/labs/03-packer-variaveis/) | Como escondo segredo do output? |
| `post-processor "docker-tag"` | [03](docs/labs/03-packer-variaveis/) | Como dou nome/tag à imagem? |
| Multi-source + `only` / `except` | [04](docs/labs/04-packer-multi-source/) | Uma definição, várias bases (= AWS + Azure) |
| `${source.name}` | [04](docs/labs/04-packer-multi-source/) | Como diferencio o output por source? |
| `post-processor "manifest"` | [05](docs/labs/05-packer-manifest/) | Como o Terraform descobre qual imagem usar? |

### Terraform

| Conceito | Lab | Responde |
|---|---|---|
| `init` / `plan` / `apply` / `destroy` | [06](docs/labs/06-tf-workflow-core/) | O ciclo básico |
| **State** — o mapa | [06](docs/labs/06-tf-workflow-core/) | O que é o `.tfstate` e por que perder ele dói? |
| `variable` / `output` / `validation` | [07](docs/labs/07-tf-variaveis-outputs/) | A interface do stack |
| Precedência de variáveis (Terraform) | [07](docs/labs/07-tf-variaveis-outputs/) | ⚠️ **Diferente do Packer** — `tfvars` vence `TF_VAR_*` |
| Dependência implícita vs `depends_on` | [08](docs/labs/08-tf-dependencias/) | Quem é criado primeiro, e por quê? |
| `count` vs `for_each` | [09](docs/labs/09-tf-count-foreach-lifecycle/) | Por que remover do meio da lista destrói o item errado? |
| `lifecycle` | [09](docs/labs/09-tf-count-foreach-lifecycle/) | `prevent_destroy`, `create_before_destroy`, `ignore_changes` |
| **Módulos** | [10](docs/labs/10-tf-modulos/) | A unidade reutilizável — a base do framework de tenant |
| `import` / drift / `moved` / `state rm` | [11](docs/labs/11-tf-state/) | Como opero o state sem destruir nada? |
| Packer → Terraform | [12](docs/labs/12-capstone-ponte/) | O pipeline de duas etapas, ponta a ponta |
| Workspaces vs diretórios | [13](docs/labs/13-capstone-ambientes/) | Como separo prod de dev *de verdade*? |
| Pipeline / empacotamento | [14](docs/labs/14-capstone-empacotar/) | Como rodo tudo com um comando? |

### Windows Server / Hyper-V

| Conceito | Lab | Responde |
|---|---|---|
| `hyperv-iso` + `Autounattend.xml` | [15](docs/labs/15-packer-hyperv-windows/) | Como instalo Windows sem clicar em nada? |
| Ansible via WinRM | [16](docs/labs/16-ansible-windows-winrm/) | Como configuro Windows por código, idempotente? |
| Golden image + Sysprep | [17](docs/labs/17-golden-image-pipeline/) | Por que Sysprep evita SID duplicado? |
| Terraform + provider Hyper-V | [18](docs/labs/18-tf-hyperv-provider/) | Como instancio N VMs a partir de uma golden image? |

### Kubernetes

| Conceito | Lab | Responde |
|---|---|---|
| Cluster com `kubeadm` | [19](docs/labs/19-k8s-cluster-hyperv/) | Como subo um cluster do zero? |
| Quota + NetworkPolicy + Ingress | [20](docs/labs/20-k8s-workload-ingress/) | Governança dentro de um namespace |
| Vault + PostgreSQL | [21](docs/labs/21-k8s-vault-postgres/) | Como injeto segredo sem hardcode em YAML? |
| Terraform + provider Kubernetes | [22](docs/labs/22-tf-kubernetes-provider/) | Namespace por tenant via mapa, com governança |

---

## Dependências entre labs

A maioria é independente, mas alguns exigem o resultado de outro:

| Lab | Precisa de | Por quê |
|---|---|---|
| 07 | 06 | Expande o **mesmo** stack (`web-basic`), não cria outro |
| 12 | 02, 05 | Usa provisioners (02) e o `manifest.json` (05) |
| 16 | 15 | Precisa da VM Windows rodando |
| 17 | 15, 16 | Reusa o `Autounattend.xml` e o playbook |
| 18 | 17 | Consome a golden image (VHDX) |
| 20, 21, 22 | 19 | Precisam do cluster de pé |

---

## Agora

**Bloco 3 (Capstone) fechado — Labs 12, 13 e 14 completos.**

**Lab 15 (Packer + Hyper-V) fechado — golden image Windows Server 2022
construída com sucesso** (VHDX 10.25GB, `packer/output-win2022/`). Quatro
problemas reais resolvidos no caminho (`oscdimg` ausente, falta de RAM,
limitação estrutural do teclado sintético em Gen2, `ProductKey` exigido por
mídia VL) — detalhes nas Notas do README. Os dois "Quebre isto" foram
pulados por decisão informada (10 anos de experiência real em build de
imagem). **VHDX mantido de propósito** — vira a base da VM do Lab 16, em vez
de reinstalar o Windows do zero.

**Próximo: Lab 16 — Ansible via WinRM.** Vai reaproveitar o VHDX do Lab 15
pra criar a VM de teste (mais rápido que reinstalar). Ainda não iniciado.

**Plano revisado pro fim de semana (definido em 2026-08-07 à noite, ritmo
real à frente da estimativa original):**

- **Sábado:** fechar o resto do Bloco 4 — Lab 16 (Ansible), Lab 17 (golden
  image pipeline, expandido com `post.ps1` real do JZ + multi-versão
  2022/2025/Win11 — ver nota no Lab 17 mais abaixo), Lab 18 (Terraform +
  provider Hyper-V). Objetivo: **Bloco 4 inteiro fechado até domingo começar**.
- **Domingo:** Bloco 5 — Kubernetes (Labs 19-22), o "mini-KOB" que replica a
  stack real de SRE do JZ (cluster + Vault + PostgreSQL). `#sonho` — é o
  bloco que mais conecta com o trabalho dele.
- Contexto pra calibrar: o plano anterior (03/08) reservava um dia só pro
  Lab 15 "rodando, não necessariamente terminado", e outro dia pro Lab 16.
  Na prática, Bloco 3 inteiro + Lab 15 completo couberam numa sessão de
  3h24min (07/08 à noite) — ritmo mais rápido que o estimado.

Depois do Bloco 3, a continuação é outro escopo — ver
[`docs/PROXIMO-TRACK.md`](docs/PROXIMO-TRACK.md): provisionamento multi-cloud
(AWS/Azure/OCI) + um gerenciador local unificando nuvem privada (Hyper-V) e
pública, alinhado com a vaga-alvo. A escada de degraus que falta até lá está
em [`docs/ANALISE-MELHORIAS.md`](docs/ANALISE-MELHORIAS.md).

## Backlog

Pendências que não pertencem a um lab específico:

- [x] **Refazer os READMEs dos Labs 01–14 no formato novo** — concluído em
      2026-08-08. Todos com `## Teoria` antes da prática e um script único
      por passo (`Write-RepoFile`, que grava LF + UTF-8 sem BOM). Cada script
      foi verificado executando de verdade num diretório temporário e
      comparando com os arquivos reais do repo. **15 dos 23 labs** estão no
      formato novo (01–15); os 8 restantes são o `00-setup` e os Labs 16–22,
      que ainda não foram executados e já nascem nesse formato.
      Isso destrava o gerador do curso HTML — ver
      [`../labs-html/PLANO-CURSO.md`](../labs-html/PLANO-CURSO.md), item 6.1.
- [ ] Adicionar tasks `tf:init` / `tf:plan` / `tf:apply` / `tf:destroy` ao
      `Taskfile.yml` — a regra era "só depois de fazer na mão"; já foi feito
      nos Labs 06/07, pode adicionar
- [ ] Decidir Hyper-V local (`hyperv-iso`) vs Azure (`azure-arm`) no Bloco 4 —
      há US$100 de créditos Azure disponíveis
- [ ] Confirmar se a vaga é híbrida (on-prem + cloud) ou só nuvem pública —
      muda se vale investir em `vsphere` / `dell-redfish`
- [ ] Exercício de consolidação adiado: refazer um lab do zero sem consultar
- [ ] Drift detection agendado no CI (`terraform plan -detailed-exitcode`) —
      depois do Bloco 2
- [ ] `tfsec` / `checkov` no CI — depois do Bloco 2
- [ ] Gaps do "conceito completo" fora do escopo da vaga: baremetal→SO
      (Redfish / PXE / MAAS), VMware / vSphere, GitOps (só mencionado no Lab 22)

## Progresso

| Bloco | Labs | Status |
|---|---|---|
| 0 — Setup | 00 | ✅ 19/19 |
| 1 — Packer | 01–05 | ✅ 46/46 |
| 2 — Terraform | 06–11 | ✅ 73/73 |
| 3 — Capstone | 12–14 | 🔶 35/36 |
| 4 — Windows/Hyper-V | 15–18 | 🔶 11/42 |
| 5 — Kubernetes | 19–22 | ⬜ 0/53 |
| **Total** | | **184/269 (68%)** |

> Mantido em sincronia com `task status`, que lê este arquivo. Se divergir,
> o script é a fonte da verdade — a tabela é conveniência.

---

## Bloco 0 — Setup da estação

Preparar a máquina: toolchain, git, SSH. É o único bloco inteiramente manual
do repo — e justamente por isso ganhou automação própria
([`automation/setup/`](automation/setup/), rodável com `task setup`).

### 00-setup

**Ensina:** o ambiente mínimo para todos os outros labs.
**Automação:** `task setup` valida cada passo e marca os itens abaixo sozinho.

- [x] Instalar Terraform (`winget install Hashicorp.Terraform`)
- [x] Instalar Packer (`winget install Hashicorp.Packer`)
- [x] Instalar Docker Desktop com backend WSL2
- [x] Habilitar integração WSL no Docker Desktop
- [x] Instalar extensão HashiCorp Terraform no VS Code
- [x] Inicializar repositório Git na pasta `labs/`
- [x] Configurar chave SSH `ssh-iac` no Ubuntu WSL
- [x] Configurar chave SSH `ssh-iac` no PowerShell/Windows
- [x] Validar `ssh -T git@github.com` no Windows/Git Bash → autenticou como `jezielbrizolla`
- [x] Validar `ssh -T git@github.com` dentro do WSL Ubuntu → autenticou como `jezielbrizolla`
- [x] Criar repositório remoto no GitHub — <https://github.com/jezielbrizolla/IaC>
- [x] Adicionar `origin` (SSH) em `labs/` apontando para `git@github.com:jezielbrizolla/IaC.git`
- [x] Fazer commit inicial em `labs/`
- [x] Enviar o primeiro push para `origin main`
- [x] Validar `terraform -version` → 1.15.8
- [x] Validar `packer version` → 1.16.0
- [x] Validar `docker run hello-world`
- [x] Instalar go-task (`winget install Task.Task`)
- [x] Validar `task --version` → 3.52.0

**Correção aplicada durante o lab:** `wsl-ssh-setup.sh` — `chmod 600 ~/.ssh/config`
quebrava com `set -e` se o arquivo ainda não existisse. Agora só roda o `chmod`
se o arquivo existir (idem para a chave privada `ssh-iac`, que também precisa
estar em 600).

---

## Bloco 1 — Packer

Construir imagens como código. O alvo aqui é Docker (rápido, gratuito, local),
mas a estrutura do HCL é a mesma que se usa com `amazon-ebs`, `azure-arm` ou
`vsphere-iso` — só muda o `source`.

### 01-packer-primeiro-build

**Ensina:** o esqueleto mínimo de um template — os três blocos (`packer`,
`source`, `build`) e por que `packer init` existe.
**Artefato:** `packer/templates/ubuntu-base.pkr.hcl`

- [x] Escrever o template com `required_plugins` + `source "docker"` + `build`
- [x] `task packer:init` — plugin baixado
- [x] `packer fmt` aplicado
- [x] `task packer:validate IMAGE=ubuntu-base` sem erros
- [x] `task packer:build IMAGE=ubuntu-base` produziu uma imagem
- [x] `docker image ls --all --filter "dangling=true"` mostra a imagem (aparece como `<untagged>` — normal, ainda sem tag; o lab 04 fecha isso)
- [x] Quebrei: comentei `required_plugins` **e** isolei o cache de plugins, rodei o build e li o erro real ("The source docker is unknown by Packer")
- [x] Sei explicar em 1 frase o que `commit = true` faz
- [x] Notas preenchidas no README

### 02-packer-provisioners

**Ensina:** fazer a imagem *fazer algo* — instalar e configurar software no
build time, e por que a ordem dos provisioners é a ordem de execução (não há
grafo de dependência como no Terraform).
**Artefatos:**

- `packer/templates/ubuntu-nginx.pkr.hcl`
- `packer/scripts/install-nginx.sh`
- `packer/files/nginx/default.conf`

- [x] Escrever a config do nginx
- [x] Escrever o template com `provisioner "shell" { inline = [...] }` + `provisioner "file"`
- [x] `packer init` / `packer build` OK
- [x] Container rodando e servindo a config própria
- [x] Resposta HTTP retorna o texto de teste
- [x] Container de teste removido
- [x] Migrar `inline` → `script` externo
      <br>_Nota: o script de refactor foi escrito por mim (JZ) — regex + here-string em
      PowerShell — mas quem aterrissou o arquivo na estrutura nova foi o Claude,
      durante a reestruturação do repo. O conceito (extrair para script reutilizável)
      foi entendido; a execução final veio junto da migração._
- [x] Rebuild com script externo funcionou igual
- [x] Quebrei: inverti a ordem `file` antes de `shell`, li o erro ("must be a directory" — não o "no such file" esperado), voltei ao normal via `git checkout`
- [x] Notas preenchidas no README

### 03-packer-variaveis

**Ensina:** parametrizar — o mesmo template produzindo imagens diferentes sem
editar o arquivo, e as quatro formas de passar valor.
**Artefatos:**

- `packer/templates/app-versioned.pkr.hcl`
- `packer/vars/app-versioned.pkrvars.hcl`

- [x] Escrever o template com `variable`, `locals`, `post-processor "docker-tag"`
- [x] Escrever `packer/vars/app-versioned.pkrvars.hcl`
- [x] Build com default (`app_version=1.0`)
- [x] Build com `-var "app_version=2.0"`
- [x] Build com `-var-file="vars/app-versioned.pkrvars.hcl"` (1.1)
- [x] Build com `PKR_VAR_app_version` (3.0)
- [x] `docker images meuapp` mostra as 4 tags
- [x] `packer inspect .` rodado e entendido
- [x] Quebrei: variável obrigatória sem default/valor → li o erro ("Unset variable"), numa cópia temporária, sem editar o template do repo
- [x] Testei `sensitive = true` e confirmei que o valor não aparece nem no build nem no `packer inspect` (`<unknown>`)
- [x] Notas preenchidas no README

### 04-packer-multi-source

**Ensina:** um `build`, vários `source` em paralelo, com provisioners
condicionados por `only`/`except`. É exatamente o padrão que vira "mesma
imagem para AWS e Azure" — só troca o tipo do `source`.
**Artefato:** `packer/templates/multi-base.pkr.hcl`

- [x] Escrever o template com dois `source` (ubuntu, alpine)
- [x] Provisioners com `only = [...]` separados por source
- [x] `post-processor "docker-tag"` usando `tags = ["${source.name}"]`
- [x] `task packer:build IMAGE=multi-base` produziu as duas imagens num único comando
- [x] `docker images multi-base` mostra `multi-base:ubuntu` e `multi-base:alpine`
- [x] Quebrei: um provisioner `apt-get` só, sem `only`, vi o Alpine falhar ("apt-get: not found", exit 127)
- [x] Li o erro completo e identifiquei em qual source falhou (docker.alpine)
- [x] Voltei para os provisioners separados
- [x] Notas preenchidas no README

### 05-packer-manifest

**Ensina:** registrar qual imagem foi produzida em formato legível por
máquina. Este JSON é o **contrato entre Packer e Terraform** — o Lab 12 vai
consumi-lo.
**Artefato:** `packer/templates/golden-manifest.pkr.hcl`

- [x] Adicionar `post-processor "manifest"` ao template
- [x] `task packer:build` / `packer build` gerou `manifest.json`
- [x] Rodei 2+ builds e confirmei que `builds[]` acumula entradas
- [x] Identifiquei os campos: `name`, `artifact_id`, `packer_run_uuid`, `custom_data`, `last_run_uuid`
- [x] Quebrei: 5 builds seguidos (1.0 a 5.0), decidi a regra pra pegar "a imagem certa"
- [x] Regra escolhida anotada nas Notas do README (`last_run_uuid` == `packer_run_uuid`, não posição do array)
- [x] Sei explicar por que este JSON é a ponte pro Terraform

---

## Bloco 2 — Terraform

Provisionar infraestrutura. Mesma lógica do Packer para `init`/`fmt`/`validate`,
mas com uma diferença central: o Terraform mantém **state** — um mapa entre o
que você declarou e o que existe de verdade.

### 06-tf-workflow-core

**Ensina:** o ciclo completo e, o mais importante, **o que é o state**. Drift,
`import`, `moved` e "perdi o state" são todos consequência desse conceito.
**Artefato:** `terraform/stacks/web-basic/main.tf`

- [x] Escrever o stack com `terraform{}` + `provider "docker"` + `docker_image` + `docker_container`
- [x] `terraform -chdir=... init` OK — provider `kreuzwerker/docker v3.9.0`, lock file criado
- [x] `terraform -chdir=... fmt` / `validate` limpos
- [x] `terraform -chdir=... plan` revisado antes de aplicar (`2 to add, 0 to change, 0 to destroy`)
- [x] `terraform -chdir=... apply -auto-approve` OK
- [x] `curl localhost:8080` retorna a página do nginx (StatusCode 200)
- [x] Li o `terraform.tfstate` e identifiquei `resources`, `attributes`, `serial`, `lineage`
- [x] Comparei o `id` do state com `docker inspect lab06-web` — idênticos
- [x] Quebrei: apaguei o state com o container no ar, vi o plan querer recriar tudo (`2 to add`)
- [x] Restaurei o backup do state — `plan` voltou a `No changes`
- [x] `terraform destroy -auto-approve` deixou `docker ps -a` limpo
- [x] Notas preenchidas no README

### 07-tf-variaveis-outputs

**Ensina:** transformar um stack fixo em parametrizável. Primeiro passo
concreto rumo a "um tenant = mesma definição, valores diferentes".
**Artefato:** `terraform/stacks/web-basic/` (expande o stack do Lab 06)
**Depende de:** Lab 06

- [x] Criar `variables.tf` com `container_name`, `external_port` (com `validation`), `labels`
- [x] Modificar `main.tf`: `locals.full_name` no `name`, `var.external_port` na porta
- [x] Criar `outputs.tf` com `url` e `container_id`
- [x] Criar `terraform.tfvars` com `external_port = 8081`
- [x] Apply usando `terraform.tfvars` (8081) — destroy+create confirmado pela mudança de nome (`lab06-web` → `web-lab`)
- [x] Apply sobrescrevendo com `-var` (8082) — `-var` venceu o `tfvars`, como esperado
- [x] Apply com `TF_VAR_external_port` (8083) sem `terraform.tfvars` no caminho — env var venceu de verdade
- [x] `terraform output` mostrando `url` e `container_id`
- [x] Quebrei: `external_port=80`, li a mensagem de validação
- [x] Notei a diferença de comportamento create vs replace na validação
- [x] Reescrevi a `error_message` com minhas palavras ("A porta externa deve estar entre 1024 e 65535...")
- [x] Sei explicar a diferença entre `variable` e `locals`
- [x] `terraform destroy` no final — `docker ps -a` confirmado limpo
- [x] Notas preenchidas no README

### 08-tf-dependencias

**Ensina:** como o Terraform decide a ordem de criação. Dependência implícita
(por referência de atributo) é a regra; `depends_on` é a exceção.
**Artefato:** `terraform/stacks/web-network/main.tf`

- [x] Criar `main.tf` com `docker_network`, `docker_volume`, `docker_container` (referência implícita)
- [x] `terraform apply` OK
- [x] `terraform graph > graph.dot` gerado e lido (ou visualizado no Graphviz online)
- [x] Reescrevi usando `depends_on` explícito e comparei o grafo
- [x] Entendi por que o grafo NÃO muda — a diferença é o dado que trafega, não a ordem
- [x] Voltei para a versão com referência de atributo (a correta)
- [x] Conclusão sobre implícito vs `depends_on` anotada nas Notas
- [x] Quebrei: criei `circular.tf` com dependência circular, li o erro `Cycle: ...`
- [x] Apaguei `circular.tf` depois do teste
- [x] Notas preenchidas no README

### 09-tf-count-foreach-lifecycle

**Ensina:** identidade por **índice** (`count`) vs por **chave** (`for_each`) —
e por que isso é a diferença entre um deploy tranquilo e um incidente. Mais os
guardrails de `lifecycle`.
**Artefato:** `terraform/stacks/web-count-foreach/main.tf` + `count.tf`

- [x] Criar `main.tf` com a imagem compartilhada
- [x] Criar `count.tf`, apply com 3 containers
- [x] Remover `"b"` da lista, `plan` (sem aplicar) e ler o destroy/recreate indevido
- [x] `terraform destroy` e trocar para `foreach.tf`
- [x] Apply com `for_each`, remover `"b"`, `plan` e confirmar que só ele é destruído
- [x] Diferença count vs for_each anotada nas Notas
- [x] Testar `create_before_destroy = true` e ver a ordem inverter no plan
- [x] Testar `ignore_changes = [image]`
- [x] Testar `prevent_destroy = true` e ler o erro do destroy (depois remover)
- [x] `terraform destroy` limpo no final
- [x] Notas preenchidas no README

> **Conexão com o objetivo:** o mapa do `for_each` é o padrão de tenant —
> cada entrada é um tenant, adicionar uma linha provisiona um novo, remover
> destrói só aquele.

### 10-tf-modulos

**Ensina:** empacotar e reutilizar. O módulo encapsula "o que um tenant
precisa"; os inputs são o que muda por tenant; os outputs são o que o próximo
estágio consome.
**Artefatos:** `terraform/modules/webapp/` + `terraform/stacks/web-modules/`

- [x] Criar `modules/webapp/` com `main.tf`, `variables.tf`, `outputs.tf`
- [x] Criar `main.tf` (root) chamando `module "app_a"` e `module "app_b"`
- [x] Criar `outputs.tf` (root) expondo `module.app_a.url` / `module.app_b.url`
- [x] `terraform init` OK (baixou/registrou os módulos)
- [x] `terraform apply` — duas apps no ar
- [x] `curl localhost:8091` e `curl localhost:8092` respondem
- [x] Testei os 3 formatos de `source` (local aplicado, git/registry só lidos)
- [x] Quebrei: módulo novo sem `init` antes → erro
- [x] Testei: recurso novo dentro de módulo existente sem `init` → funciona
- [x] `terraform destroy` limpo
- [x] Notas preenchidas no README

> **Conexão com o objetivo: este é *o* lab.** Um tenant = uma chamada de
> módulo com variáveis diferentes. Corrigir um guardrail no módulo corrige
> em todos os tenants de uma vez.

### 11-tf-state

**Ensina:** operar o state sem destruir nada — trazer recurso existente para
dentro (`import`), detectar drift, renomear sem recriar (`moved`), e remover
do controle sem apagar (`state rm`).
**Stack:** `terraform/stacks/` (vários exercícios)

- [x] Base aplicada (`docker_container.app`)
- [x] `terraform state list` / `state show` explorados
- [x] Container `orfao` criado fora do Terraform
- [x] `terraform import docker_container.orfao <id>` rodou
- [x] Ajustei a config até `terraform plan` ficar vazio para `orfao`
- [x] Testei também o bloco `import {}` + `-generate-config-out`
- [x] Drift: `docker stop orfao` → `terraform plan` detectou
- [x] Testei `-refresh-only` e entendi a diferença
- [x] Renomeei `app` → `web`, vi o plan querer destruir/criar
- [x] Resolvi com `terraform state mv`
- [x] Resolvi (de novo, do zero) com bloco `moved {}`
- [x] `terraform state rm docker_container.orfao` — confirmei que o container continua vivo
- [x] Sei explicar a diferença entre `state rm` e `destroy`
- [x] Limpeza final: `docker rm -f orfao` + `terraform destroy`
- [x] Notas preenchidas no README

> **Conexão com o objetivo:** com N tenants, o state fica separado por tenant
> ou por stack? O que acontece com os outros se o state de um corromper?

---

## Bloco 3 — Capstone

Juntar Packer e Terraform num pipeline só, separar ambientes, e empacotar como
repositório apresentável.

### 12-capstone-ponte

**Ensina:** o pipeline de duas etapas ponta a ponta — Packer produz a imagem e
escreve o manifest; Terraform lê o manifest e sobe exatamente aquela imagem.
**Depende de:** Labs 02 e 05
**Artefatos:** `packer/templates/capstone-nginx.pkr.hcl` + `packer/files/capstone/default.conf` + `terraform/stacks/capstone-ponte/main.tf`

- [x] Criar `default.conf`, `capstone-nginx.pkr.hcl` (reaproveita `packer/scripts/install-nginx.sh`, com `post-processor "manifest"`)
- [x] `task packer:build IMAGE=capstone-nginx` gerou `packer/manifest.json`
- [x] Criar `terraform/stacks/capstone-ponte/main.tf` lendo o manifest via `data "local_file"` + `jsondecode()` (por `last_run_uuid`, não posição de array)
- [x] `terraform apply` subiu o container com a imagem do Packer
- [x] `curl localhost:8080` retorna `capstone v1`
- [x] Editei `default.conf`, rebuild do Packer, `terraform plan` propôs substituir
- [x] `terraform apply` e confirmei `capstone v2` no navegador
- [x] Quebrei: renomeei `manifest.json` pra `.bak`, li o erro do `data` source
- [x] Restaurei o manifest e voltei a funcionar
- [x] `terraform destroy` limpo — state final com 0 recursos
- [x] Notas preenchidas no README

### 13-capstone-ambientes

**Ensina:** separar ambientes de verdade — e por que `terraform workspace`
**não** é a resposta para prod/non-prod (workspaces compartilham backend e
credencial; um `select` errado aplica em prod sem aviso).
**Artefatos:** `terraform/stacks/capstone-ambientes-ws/` (Parte 1) + `terraform/envs/{dev,prod}/` reaproveitando `terraform/modules/webapp/` do Lab 10 (Parte 3)

- [x] Criar `main.tf` usando `terraform.workspace`
- [x] Criar `dev.tfvars` e `prod.tfvars`
- [x] `terraform workspace new dev` / `new prod`
- [x] Apply em `dev` com `dev.tfvars`
- [x] Apply em `prod` com `prod.tfvars`
- [x] Confirmei `terraform.tfstate.d/` com um state por workspace
- [x] Reproduzi a armadilha: selecionei `prod` e apliquei `dev.tfvars` por engano
- [x] Entendi por que não há barreira estrutural entre workspaces (prod ficou fora do ar de verdade — conflito de porta com o container real de dev)
- [x] Destruí a Parte 1/2 antes da Parte 3 (nomes literais colidem com o Docker real — achado durante o lab, não previsto no README original)
- [x] Criei `envs/dev/` + `envs/prod/` reaproveitando `modules/webapp/` (sem módulo novo)
- [x] Apply funcionando nos dois diretórios separados, confirmado por evidência (`docker ps` + state com 4 recursos cada)
- [x] Conclusão sobre "por que diretório > workspace para prod/non-prod" anotada nas Notas
- [x] Limpeza completa (destroy nos dois modelos, workspaces deletados)
- [x] Notas preenchidas no README

> **Conexão com o objetivo:** isolamento por diretório/backend é o padrão que
> escala para isolamento por tenant.

### 14-capstone-empacotar

**Ensina:** transformar os labs num repositório que outra pessoa clona e roda
sem te perguntar nada. É o entregável de portfólio.

- [x] Criar tasks `capstone:build` / `capstone:destroy` no `Taskfile.yml`
      (não `build.ps1`/`destroy.ps1` soltos — repo já roda tudo por `task`)
- [x] `README.md` do capstone (Labs 12 e 14): o que é, por quê, como rodar
- [x] Diagrama mermaid incluído (README do Lab 14)
- [x] `.terraform.lock.hcl` confirmado como versionado (`git check-ignore -v` vazio)
- [x] Versões pinadas (provider, plugin Packer, `required_version` Terraform)
- [x] Seção "próximos passos: multi-cloud" linkando pro `docs/PROXIMO-TRACK.md`
- [x] `task capstone:build` rodou do zero e funcionou (`curl` confirmou `capstone v2`)
- [x] `task capstone:destroy` + `task clean` limparam tudo (conferido com `docker ps -a`, liberou 2.2GB)
- [ ] Pedi pra alguém (ou eu mesmo, dias depois) seguir só o README sem ajuda
- [x] Commit + push do capstone
- [x] Notas preenchidas no README

---

## Bloco 4 — Windows Server (Hyper-V)

O mesmo workflow de golden image, agora com VM de verdade em vez de container.
Replica o processo usado para golden images de servidor.

> ⚠️ **Decisão pendente:** rodar local com `hyperv-iso` ou na nuvem com
> `azure-arm` (imagem do Marketplace evita o download manual da ISO). Ver
> [Backlog](#backlog).
>
> **Pré-requisitos deste bloco:** ver [`docs/labs/00-setup/SETUP-HYPERV.md`](docs/labs/00-setup/SETUP-HYPERV.md)
> (Hyper-V habilitado, Virtual Switch, ISOs, `oscdimg`, Ansible no WSL).

### 15-packer-hyperv-windows

**Ensina:** instalação desassistida — o `Autounattend.xml` substitui horas de
cliques em wizard, e o WinRM é como o Packer conversa com Windows.
**Artefatos:** `packer/templates/win2022-base.pkr.hcl` + `packer/vars/win2022-base.pkrvars.hcl` + `packer/files/win2022-base/Autounattend.xml`

- [x] Virtual Switch externo criado no Hyper-V (`LabSwitch`) — *feito fora de ordem, durante o setup do ambiente*
- [x] ISO do Windows Server 2022 baixada em `labs\ISOs\` (mídia VL, benefício Visual Studio subscription — não Evaluation)
- [x] Rodar o script do Passo 1 do README — cria os 3 arquivos de uma vez
- [x] `task packer:validate IMAGE=win2022-base` → sem erros
- [x] `task packer:build IMAGE=win2022-base -- -var-file="vars/win2022-base.pkrvars.hcl"` → build inicia
- [x] Observar no Hyper-V Manager: VM criada, Windows instalando sozinho
- [x] WinRM conecta e provisioner PowerShell roda com sucesso
- [x] Build completa → imagem exportada em `packer/output-win2022/` (VHDX de 10.25GB confirmado)
- [x] **Quebre:** comentar `cd_files` → timeout de WinRM — *pulado por decisão
      informada: 10 anos de experiência real em build de imagem já cobrem
      esse cenário; os 4 problemas reais resolvidos nesta sessão (oscdimg,
      RAM, Gen2, ProductKey) já foram o exercício de troubleshooting*
- [x] **Quebre:** dessincronizar senha entre Autounattend e vars → falha de auth — *idem*
- [x] Limpeza: VM já foi destruída pelo próprio Packer (padrão do build).
      `packer/output-win2022/` (VHDX 10.25GB) **mantido de propósito** —
      decisão do JZ, vira a base da VM do Lab 16 em vez de reinstalar
      Windows do zero. Apagar quando o Lab 16 não precisar mais dele.

### 16-ansible-windows-winrm

**Ensina:** configurar Windows por código, de forma idempotente — e a
diferença entre módulos declarativos (`win_feature`) e `win_shell` (que sempre
reporta `changed`).
**Depende de:** Lab 15 (VM rodando)
**Artefato:** `ansible/playbooks/`

- [ ] Ansible + pywinrm instalados no WSL (`ansible --version`, `python -c "import winrm"`)
- [ ] VM Windows Server rodando (IP anotado)
- [ ] Criar `inventory.yml` com credenciais WinRM
- [ ] Criar `playbook.yml` com tasks de feature, hardening e validação
- [ ] `ansible ... win_ping` → pong (conectividade OK)
- [ ] `ansible-playbook` roda sem erros
- [ ] Confirmar: IIS instalado e rodando na VM
- [ ] Confirmar: `provisioned.txt` existe em `C:\Logs\Automation\`
- [ ] Confirmar: firewall habilitado, regra WinRM presente
- [ ] **Quebre:** rodar playbook 2x → observar idempotência (ok vs changed)
- [ ] **Quebre:** senha errada no inventory → HTTP 401
- [ ] **Quebre:** porta 5986 sem cert → falha SSL

### 17-golden-image-pipeline

**Ensina:** o pipeline completo de golden image Windows — Packer cria, Ansible
provisiona, Sysprep generaliza. Sem Sysprep, todas as VMs clonadas herdam o
mesmo SID (problema sério em domínio).
**Depende de:** Labs 15 e 16

> **Quando chegar aqui:** o JZ vai trazer um `post.ps1` real (script de
> pós-instalação que ele já usa) pra substituir o playbook genérico deste
> lab, e expandir pra 2022/2025/Win11 (ISOs já em `labs/ISOs/`, mesmo
> padrão multi-source do Lab 04). Decisão em aberto: manter PowerShell puro,
> converter pra Ansible, ou separar num "Lab 17.5" pra não misturar o
> conceito básico do pipeline com a expansão multi-versão. Resolver na hora.

- [ ] Copiar `Autounattend.xml` do lab 15
- [ ] Criar `golden.pkr.hcl` com provisioners PowerShell + Ansible + Sysprep
- [ ] Criar `playbook-golden.yml` (features + hardening + updates)
- [ ] `packer init .` e `packer build` → build completo
- [ ] Ansible provisiona via WinRM durante o build
- [ ] Sysprep executa e VM desliga sozinha
- [ ] `golden-manifest.json` gerado
- [ ] **Quebre:** sem Sysprep → SID duplicado
- [ ] **Quebre:** timeout curto → perda de conexão no reboot

### 18-tf-hyperv-provider

**Ensina:** fecha o ciclo — Packer cria a imagem uma vez, Terraform instancia
quantas VMs quiser a partir dela. É o mesmo padrão de AMI + Auto Scaling Group
na AWS.
**Depende de:** Lab 17 (golden image VHDX)

- [ ] Golden image VHDX do lab 17 disponível
- [ ] Criar `main.tf` com provider `taliesins/hyperv`
- [ ] `terraform init` → provider baixado
- [ ] `terraform apply` → VM criada no Hyper-V a partir da golden image
- [ ] Verificar VM rodando: `Get-VM lab18-vm*`
- [ ] Escalar para 2 instâncias → só a segunda é criada
- [ ] Inspecionar `terraform.tfstate` → IDs do Hyper-V mapeados
- [ ] **Quebre:** deletar VM fora do TF → drift detectado no plan
- [ ] **Quebre:** reduzir count → entender destroy vs prevent_destroy
- [ ] `terraform destroy` → limpeza total

---

## Bloco 5 — Kubernetes (mini-KOB)

Cluster local em VMs Hyper-V, replicando a stack do KOB: workloads, Vault,
PostgreSQL, e Terraform como orquestrador de governança.

> **Requisito de memória:** duas VMs de 4GB + host. Reserve ~12GB livres antes
> de começar o Lab 19.

### 19-k8s-cluster-hyperv

**Ensina:** subir um cluster do zero com `kubeadm` — e por que swap desligado
e CNI instalado não são opcionais.
**Artefato:** `ansible/playbooks/`

- [ ] ISO Ubuntu Server 24.04 baixada
- [ ] Criar VM `k8s-cp` (control-plane) no Hyper-V
- [ ] Criar VM `k8s-w1` (worker) no Hyper-V
- [ ] Instalar Ubuntu em ambas (SSH habilitado, IPs estáticos)
- [ ] Desabilitar swap em ambas
- [ ] Configurar módulos de kernel e sysctl em ambas
- [ ] Instalar containerd em ambas (SystemdCgroup = true)
- [ ] Instalar kubeadm, kubelet, kubectl em ambas
- [ ] `kubeadm init` no control-plane → cluster inicializado
- [ ] Configurar kubectl no CP (`$HOME/.kube/config`)
- [ ] Instalar Flannel CNI
- [ ] `kubeadm join` no worker → nó juntou ao cluster
- [ ] `kubectl get nodes` → 2 nós Ready
- [ ] Copiar kubeconfig para o host Windows
- [ ] `kubectl get nodes` funciona do Windows
- [ ] **Quebre:** swap ligado → erro no kubeadm
- [ ] **Quebre:** sem CNI → nós NotReady
- [ ] Pod de teste nginx roda no worker

### 20-k8s-workload-ingress

**Ensina:** governança dentro de um namespace — ResourceQuota force que todo
pod declare `requests`, e NetworkPolicy bloqueia tráfego não autorizado.
**Depende de:** Lab 19
**Artefato:** `k8s/manifests/`

- [ ] Cluster do lab 19 rodando
- [ ] Instalar Ingress NGINX controller
- [ ] Criar e aplicar: namespace, deployment, service, ingress
- [ ] Criar e aplicar: resourcequota, networkpolicy
- [ ] `kubectl -n lab20-app get all` → pods Running
- [ ] Pods distribuídos no worker (verificar com `-o wide`)
- [ ] ResourceQuota mostra Used vs Hard
- [ ] Scale para 5 → cabe; scale para 15 → recusado pela quota
- [ ] **Quebre:** deployment sem requests + quota ativa → falha
- [ ] **Quebre:** NetworkPolicy bloqueando tráfego inter-pod
- [ ] Limpeza: `kubectl delete namespace lab20-app`

### 21-k8s-vault-postgres

**Ensina:** segredo injetado por sidecar — as credenciais chegam no pod sem
estar no YAML, em ConfigMap ou em Secret do Kubernetes.
**Depende de:** Lab 19
**Artefato:** `k8s/helm/`

- [ ] Helm instalado
- [ ] Vault instalado via Helm (dev mode + injector)
- [ ] PostgreSQL instalado via Helm (namespace database)
- [ ] Segredo criado no Vault (`secret/lab21/db`)
- [ ] Kubernetes auth habilitado no Vault
- [ ] Policy + role criados para `lab21-sa`
- [ ] Criar `app-with-vault.yml` com annotations de Vault inject
- [ ] Pod do app roda e mostra "DB OK" nos logs
- [ ] `cat /vault/secrets/db` mostra credenciais injetadas pelo sidecar
- [ ] **Quebre:** policy deny → pod em loop
- [ ] **Quebre:** ServiceAccount errado → auth falha
- [ ] **Quebre:** deletar segredo → sidecar falha no refresh
- [ ] Limpeza: `helm uninstall`, `kubectl delete namespace`

### 22-tf-kubernetes-provider

**Ensina:** Terraform gerenciando a infra base do cluster (namespaces, quotas,
RBAC, policies) — e onde está o limite: workload muda rápido demais, isso é
trabalho de GitOps.
**Depende de:** Lab 19
**Artefato:** `terraform/stacks/`

- [ ] Cluster rodando e kubectl configurado
- [ ] Criar `main.tf` com provider kubernetes + namespaces via for_each
- [ ] `terraform init` → provider baixado
- [ ] `terraform apply` → namespaces + quotas + policies criados
- [ ] `kubectl get namespaces -l managed-by=terraform` → dev e prod
- [ ] ResourceQuota diferente em dev vs prod (verificar)
- [ ] NetworkPolicy deny-all apenas em prod
- [ ] Adicionar namespace "staging" ao mapa → `plan` cria só o novo
- [ ] **Quebre:** deletar namespace via kubectl → drift no plan
- [ ] **Quebre:** recurso manual dentro do namespace → TF não sabe
- [ ] `terraform destroy` → limpeza completa

> **Conexão com o objetivo:** este lab é o mais próximo do alvo final —
> provisiona namespace por tenant a partir de um mapa, com quota e policy
> aplicadas automaticamente. Adicionar um tenant = adicionar uma entrada.
