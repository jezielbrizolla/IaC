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
| 01–05 | `0*-packer-*` | Bloco 1 — Packer |
| 06–11 | `*-tf-*` | Bloco 2 — Terraform |
| 12–14 | `*-capstone-*` | Bloco 3 — Capstone |

## Pré-requisitos

`terraform -version`, `packer version` e `docker run hello-world` precisam funcionar.
Se algum falhar, volte ao `00-setup`.
