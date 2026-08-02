# IaC — Packer · Terraform · Ansible · Kubernetes

Repositório de infraestrutura como código, montado com o shape de um repo de
produção: código organizado por ferramenta, camada de verbos única, e CI que
valida formatação e sintaxe em todo PR.

Serve a dois propósitos ao mesmo tempo — é o ambiente onde eu estudo e é o
artefato que mostra como eu estruturo IaC. O material didático fica isolado em
[`docs/labs/`](docs/labs/); a raiz é código.

```text
.
├── Taskfile.yml            # camada de verbos — todo comando entra por aqui
├── packer/                 # definição de imagens
│   ├── templates/          #   um .pkr.hcl por artefato
│   ├── scripts/            #   provisionamento (compartilhado entre imagens)
│   ├── files/              #   arquivos copiados para dentro das imagens
│   └── vars/               #   .pkrvars.hcl por ambiente
├── terraform/
│   ├── modules/            #   módulos reutilizáveis
│   ├── stacks/             #   stacks independentes
│   └── envs/               #   dev / prod (backend e credencial separados)
├── ansible/
│   ├── playbooks/
│   ├── roles/
│   └── inventory/
├── k8s/
│   ├── manifests/
│   └── helm/
├── automation/             # scripts de apoio (setup de máquina, testes)
│   ├── _lib/               #   módulos PowerShell compartilhados
│   └── setup/              #   provisionamento da estação de trabalho
├── docs/labs/              # material didático (ver docs/labs/README.md)
└── .github/workflows/      # CI
```

## Uso

Tudo entra pela camada de verbos — **nenhum comando exige `cd`**:

```powershell
task                                    # lista as tasks
task setup                              # prepara a máquina (uma vez)

task packer:validate                    # valida todos os templates
task packer:build IMAGE=ubuntu-nginx    # builda uma imagem
task packer:test  IMAGE=ubuntu-nginx    # smoke test da imagem

task tf:fmt                             # formata o Terraform
task status                             # progresso dos labs
task clean                              # remove imagens sem tag
```

Runner: [go-task](https://taskfile.dev) — `winget install Task.Task`.

## Convenções

**Templates são nomeados pelo artefato que produzem** (`ubuntu-nginx.pkr.hcl`),
não pela ordem em que foram escritos. O mapa de qual lab produz qual artefato
está em [`docs/labs/README.md`](docs/labs/README.md).

**Scripts e arquivos de provisionamento são compartilhados.** `packer/scripts/install-nginx.sh`
é usado por qualquer imagem que precise de nginx — não se copia script entre templates.

**Paths dentro dos templates são relativos a `packer/`**, que é o diretório onde
o Taskfile invoca o `packer`. Por isso `scripts/install-nginx.sh` e não
`../scripts/install-nginx.sh`.

**Lock files são versionados.** `.terraform.lock.hcl` e `.packer.lock.hcl` travam
as versões de provider/plugin para todo mundo — sem eles, o plan diverge entre
máquinas.

**Segredo não vai em arquivo.** Vars de configuração são versionados (fazem parte
da definição da imagem); credenciais vão em variável de ambiente (`PKR_VAR_*`,
`TF_VAR_*`) ou Vault.

**Código morto não fica comentado.** O histórico é o git — `git log -p` mostra o
que existia antes. Bloco comentado "para não perder" vira ruído que ninguém sabe
se ainda vale.

## CI

[`.github/workflows/validate.yml`](.github/workflows/validate.yml) roda em todo
push e PR:

- `packer fmt -check` + `packer init` + `packer validate` em cada template
- `terraform fmt -check` + `terraform validate` em cada stack/env
- `shellcheck` nos scripts de provisionamento

É o gate que impede HCL fora do padrão ou quebrado de chegar na main.

## Pré-requisitos

**Docker (blocos 0–3):** `terraform -version`, `packer version` e
`docker run hello-world` precisam responder. `task setup` verifica e instala o
que faltar.

**Hyper-V + Kubernetes (blocos 4–5):** Hyper-V habilitado, ISOs baixadas, Ansible
no WSL, Helm e kubectl. Ver [`docs/labs/00-setup/SETUP-HYPERV.md`](docs/labs/00-setup/SETUP-HYPERV.md).
