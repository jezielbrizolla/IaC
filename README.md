# LABs — Track 0: Packer & Terraform (local-first)

Pasta de trabalho dos labs descritos em `../track0-packer-terraform-labs.html`.
Abra aquele HTML no navegador para acompanhar o progresso; use esta pasta para escrever o código.

Repositório: https://github.com/jezielbrizolla/IaC

## Regras

1. **Cada pasta tem `README.md` + `CHECKLIST.md`.** O README é o que precisa ser
   feito — com objetivo, código, comandos exatos e critério de conclusão. O
   CHECKLIST é onde você marca o que já fez naquele lab especificamente (igual
   ao `00-setup/CHECKLIST.md`, que já usamos). README = plano; CHECKLIST = progresso.
2. **Quebre antes de concluir.** Cada README tem uma seção `## Quebre isto`. Um lab só está
   feito depois que você provocou o erro, leu a mensagem e entendeu.
3. **Sempre destrua no fim.** `terraform destroy` / `docker rm`. Deixar lixo entre labs
   gera confusão que parece bug do Terraform e não é.
4. **Anote.** Uma seção `## Notas` no fim de cada README, com o que te surpreendeu.
   Vira runbook, e é o material que você reusa numa entrevista.
5. **Quem roda os comandos do lab é o JZ, no terminal dele — não o Claude.**
   Isso vale pra `packer init/build`, `terraform apply`, `docker run`, tudo. O
   Claude explica, revisa o arquivo, interpreta erro que o JZ colar de volta —
   mas não executa o passo do lab por conta própria na primeira vez. Exceções
   claras: setup de máquina/tooling (Bloco 0, `setup-automation/`),
   verificações read-only (`docker images`, `terraform state list`, ler um
   arquivo), e **testar um `run.ps1` de automação que o próprio Claude acabou
   de escrever** — isso é validar o deliverable, não fazer o lab pelo JZ (o
   lab em si já foi feito manualmente antes de existir automação pra ele).
6. **Primeira vez: manual. Depois de entender: automatiza.** Um lab novo se
   faz na mão, com ajuda guiada, sem copiar o código do README direto (ver
   regra 1 — o código no README é gabarito/referência, a disciplina de tentar
   antes é por sua conta). Só depois de feito e entendido é que faz sentido
   criar o `run.ps1` daquele lab pra reverificar rápido nas próximas vezes.

## Ordem

| # | Pasta | Bloco |
|---|---|---|
| 00 | `00-setup` | Setup |
| 01–05 | `0*-packer-*` | Bloco 1 — Packer (Docker) |
| 06–11 | `*-tf-*` | Bloco 2 — Terraform (Docker) |
| 12–14 | `*-capstone-*` | Bloco 3 — Capstone (Docker) |
| 15–18 | `*-packer-hyperv-*` / `*-ansible-*` / `*-golden-*` / `*-tf-hyperv-*` | Bloco 4 — Windows Server (Hyper-V) |
| 19–22 | `*-k8s-*` / `*-tf-kubernetes-*` | Bloco 5 — Kubernetes (mini-KOB) |

## Pré-requisitos

**Blocos 0–3 (Docker):** `terraform -version`, `packer version` e
`docker run hello-world` precisam funcionar. Se algum falhar, volte ao `00-setup` —
ou rode `00-setup/setup-automation/setup.ps1`, que verifica/instala tudo isso
sozinho e loga o que fez.

**Blocos 4–5 (Hyper-V + Kubernetes):** Hyper-V habilitado, ISOs baixadas, Ansible
no WSL, Helm e kubectl no host. Veja `00-setup/SETUP-HYPERV.md` antes de começar
o lab 15 — nada disso é necessário para os Blocos 0–3.

## Automação (`_lib/` + `run.ps1` por lab)

`_lib/Logging.psm1` e `_lib/Checklist.psm1` são a biblioteca compartilhada de
automação do projeto inteiro — logging colorido em console + arquivo, e
atualização automática de `CHECKLIST.md` (nunca desmarca algo já feito à mão).
Usada pelo `00-setup/setup-automation/setup.ps1` (prepara a máquina) e por
qualquer `run.ps1` dentro de uma pasta de lab (ex: `01-packer-primeiro-build/run.ps1`).

Não é um orquestrador central único — cada lab que ganha um `run.ps1` é
independente, do jeito que o README + CHECKLIST já são hoje (regra 6 acima).
O padrão de um lab com automação:
```
01-packer-primeiro-build/
├── README.md
├── CHECKLIST.md
├── docker.pkr.hcl        # o que você escreveu
├── run.ps1               # ciclo automatizado (roda depois de aprender manual)
├── .gitignore             # ignora logs/*
└── logs/                  # gerado em runtime, gitignored
```
Nem todo lab precisa de `run.ps1` — só vale a pena depois que o lab já foi
feito manualmente e faz sentido reverificar/repetir rápido.
