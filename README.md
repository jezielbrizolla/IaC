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
`docker run hello-world` precisam funcionar. Se algum falhar, volte ao `00-setup`.

**Blocos 4–5 (Hyper-V + Kubernetes):** Hyper-V habilitado, ISOs baixadas, Ansible
no WSL, Helm e kubectl no host. Veja `00-setup/SETUP-HYPERV.md` antes de começar
o lab 15 — nada disso é necessário para os Blocos 0–3.
