# Análise do projeto — melhorias e o que falta até o objetivo final

Análise feita em 2026-08-03, com o repo em 41% do Track 0 (Labs 00–09
concluídos). O objetivo final declarado pelo JZ:

> "ser capaz de criar um App web local para gerenciar todos os meus tenants
> de vários providers — passo a passo, entendendo o conceito de tudo, para
> depois ir para isso."

Certificação fica para o futuro (decisão registrada; o
`plano-certificacoes-completo.html` continua existindo fora do repo, mas não
guia nada aqui).

---

## 1. O que o projeto já tem de bom (e deve manter)

- **Shape de produção**: código organizado por ferramenta (`packer/`,
  `terraform/`), docs isoladas (`docs/labs/`), artefatos nomeados pelo que
  produzem, um único ponto de entrada (`Taskfile.yml`), tudo rodando da raiz
  sem `cd`.
- **Disciplina de versionamento**: `.terraform.lock.hcl` versionado,
  `*.tfstate`/`manifest.json`/`*.dot` ignorados, `.gitattributes` prevenindo
  a classe de bug `^M`, CI com actions pinadas por tag.
- **CI real**: `validate.yml` roda `packer fmt/init/validate` e
  `terraform fmt/validate` em todo push/PR.
- **Rastreabilidade**: `TODO.md` único com índice de conceitos, dependências
  entre labs e automação (`task status`, `task setup`) lendo o mesmo arquivo.
- **Notas honestas**: cada lab registra o que quebrou de verdade e por quê —
  isso é o que diferencia o repo de um tutorial copiado.

Nada aqui precisa mudar. A análise abaixo é sobre o que **falta**.

---

## 2. A escada até o App — lacunas conceituais

O App web é a última peça de uma escada. Cada degrau abaixo é um conceito
que precisa existir **antes**, senão o App vira uma casca em cima de coisas
que você não domina. Degraus já cobertos ou planejados estão marcados.

| # | Degrau | Estado | Onde |
|---|---|---|---|
| 1 | Módulo reutilizável (1 tenant = 1 chamada) | 🔜 próximo | Lab 10 |
| 2 | Operar state sem destruir (import, drift, moved) | 🔜 | Lab 11 |
| 3 | Isolamento de ambientes/tenants (dirs vs workspaces) | 🔜 | Lab 13 |
| 4 | **State remoto com lock** | ❌ **não existe no plano** | ver 2.1 |
| 5 | **Terraform como API (saída máquina-legível)** | ❌ não existe | ver 2.2 |
| 6 | Credenciais sem hardcode (Vault) | 🔜 parcial | Lab 21 (só K8s) |
| 7 | **Registro de tenants (modelo de dados)** | ❌ não existe | ver 2.3 |
| 8 | **Camada de orquestração (Python/Go)** | ❌ não existe | ver 2.4 |
| 9 | App web (UI fina em cima do 8) | 🎯 objetivo final | próximo track |

### 2.1 State remoto com lock — a lacuna mais importante

Hoje **todo state é local** (confirmado: nenhum bloco `backend` em nenhum
stack). Para *você* estudando sozinho, funciona. Para um App gerenciar
tenants, não: o App e você no terminal seriam dois clientes concorrentes do
mesmo state — sem backend remoto com lock, um corrompe o trabalho do outro.
Este é exatamente o problema que backends resolvem, e é um conceito que a
vaga cobra ("state isolation" aparece implícito em qualquer framework
self-service).

**Como cobrir local-first, sem custo:** MinIO (S3-compatível) num container
Docker como backend `s3`, ou backend `pg` num PostgreSQL local. Vira um lab
novo de ~1h entre o Lab 11 e o capstone: migrar o state do `web-basic` de
local para remoto com `terraform init -migrate-state`, ver o lock funcionar
provocando dois `apply` simultâneos.

### 2.2 Terraform como API — o degrau que ninguém ensina

O App não vai "digitar comandos" — ele vai executar `terraform` como
subprocesso e **ler saída estruturada**. Os conceitos:

- `terraform plan -json` / `apply -json` — stream de eventos em JSON
- `terraform output -json` — outputs consumíveis por programa
- `terraform plan -detailed-exitcode` — 0/1/2 como sinal de drift (já está
  no backlog para CI; é o mesmo conceito)
- `terraform show -json` — o state inteiro como documento

Lab novo de ~1h: um script (PowerShell ou Python) que roda plan, decide
programaticamente se aplica, e extrai outputs — sem nenhum humano lendo o
terminal. É o embrião do App em 50 linhas.

### 2.3 Registro de tenants — o modelo de dados

"Gerenciar tenants" implica responder: quais tenants existem? em qual
provider? com qual stack, qual versão, qual state? Hoje essa informação não
existe em lugar nenhum — está implícita nos diretórios. Antes do App, decidir:

- um arquivo declarativo (`tenants.yaml` / `tenants.json`) que é a **fonte
  da verdade**, e do qual o `for_each` do Terraform deriva tudo (o Lab 22 já
  aponta nessa direção com namespace-por-tenant via mapa);
- ou um banco (SQLite/PostgreSQL) que o App consulta e edita.

Começar pelo arquivo: é versionável, revisável em PR, e o Terraform consome
nativamente (`yamldecode(file(...))`). O banco só se justifica quando houver
UI editando.

### 2.4 Camada de orquestração — Python ou Go

A vaga pede explicitamente "Python, Go ou Java". O App web local é a
oportunidade de praticar isso de verdade: uma API fina (FastAPI é o caminho
de menor atrito vindo de PowerShell) que expõe `POST /tenants`,
`GET /tenants/{id}/status`, `DELETE /tenants/{id}` e por baixo chama o
degrau 5. A UI web vem **depois** da API funcionar por `curl` — mesma regra
do repo: primeiro na mão, depois automatiza, aqui virando "primeiro API,
depois UI".

---

## 3. Melhorias no repo hoje (independentes do App)

Em ordem de valor:

1. **`tf:` tasks no Taskfile** — já no backlog, já liberado pela regra
   ("fazer na mão primeiro" foi cumprido nos Labs 06–09). Sem isso o
   Taskfile cobre Packer mas não Terraform, e a promessa "todo comando entra
   por aqui" está pela metade.
2. **`terraform test` nativo (v1.6+)** — nenhum teste existe. Quando o Lab
   10 criar o primeiro módulo, escrever um `.tftest.hcl` mínimo junto (dá
   pra rodar com `command = plan`, sem criar nada real). Módulo sem teste é
   o que quebra silenciosamente quando você refatorar no track seguinte.
3. **`terraform-docs`** — gera a tabela de inputs/outputs do módulo
   automaticamente. Adotar no Lab 10 junto com o primeiro módulo; vira
   task + passo de CI depois.
4. **tfsec/checkov no CI** — já no backlog para depois do Bloco 2. Mantém.
5. **Pre-commit local** — hoje o `fmt -check` só roda no CI; um hook de
   pre-commit rodando `task packer:fmt:check` + `tf:fmt:check` + markdownlint
   evita descobrir no push o que dava pra saber no commit.
6. **Limpeza menor**: existe uma pasta vazia `packer/packer/` (sobra de
   algum comando rodado do diretório errado — o mesmo bug de âncora da
   regra 7). Remover.
7. **`ansible/`, `k8s/`, `terraform/envs|modules/` vazios** — ok por design
   (são dos Blocos 3–5), mas um `.gitkeep` com uma linha de "reservado para
   o Lab NN" evitaria a impressão de lixo pra quem clona.

---

## 4. Sugestão de sequência (sem mexer na meta de sexta)

1. **Agora → sexta:** Labs 10 e 11 como planejado. No Lab 10, já incluir
   `terraform test` + `terraform-docs` (itens 2 e 3 acima) — custo marginal
   baixo, e é o momento certo: primeiro módulo.
2. **Fechamento do Bloco 2:** melhorias 1, 5 e 6 (Taskfile `tf:`,
   pre-commit, limpeza). Meia sessão.
3. **Labs novos antes do capstone** (ou dentro do próximo track): state
   remoto (2.1) e Terraform-como-API (2.2). São os dois degraus que não
   existem em nenhum plano atual e sem os quais o App não se sustenta.
4. **Próximo track** (já esboçado em [`PROXIMO-TRACK.md`](PROXIMO-TRACK.md)):
   multi-cloud + registro de tenants (2.3) + API (2.4) → **App web local**.
   O "gerenciador local" das perguntas em aberto daquele doc é exatamente
   os degraus 7–9 desta escada.

## 5. O que NÃO fazer agora

- **Não começar o App antes dos degraus 4–5.** Sem state remoto e sem saída
  máquina-legível, o App seria um `Invoke-Process` frágil lendo texto de
  terminal — retrabalho garantido.
- **Não adotar Terragrunt/Atlantis/Terraform Cloud ainda.** Todos resolvem
  problemas que você ainda não sentiu; a dor primeiro, a ferramenta depois
  (mesma filosofia dos labs). Reavaliar no próximo track.
- **Não perseguir GCP agora.** A vaga cita, mas você escolheu
  AWS/Azure/OCI — três providers já provam o padrão multi-provider; o quarto
  é repetição.
