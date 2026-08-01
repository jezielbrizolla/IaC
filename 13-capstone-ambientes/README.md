# Capstone Lab 2 — dois ambientes

**~1h**

## Objetivo
Rodar a mesma stack em `dev` e `prod`, e entender os limites de workspace.

## Parte 1 — workspaces
```
terraform workspace new dev
terraform workspace new prod
terraform workspace list
terraform workspace select dev
```
Use `terraform.workspace` no código para variar nomes e portas.
Crie `dev.tfvars` e `prod.tfvars`, e aplique cada um no seu workspace.
Inspecione a pasta `terraform.tfstate.d/` — um state por workspace.

## Parte 2 — a armadilha (o ponto do lab)
Workspaces compartilham:
- o **mesmo backend** (mesma conta/bucket)
- as **mesmas credenciais**
- o **mesmo código**, sem chance de divergir

Ou seja: um `select` errado aplica em prod achando que era dev, e não existe
barreira de permissão entre os dois. Por isso o padrão de mercado para prod/non-prod
**não** é workspace, e sim **diretórios + backends + credenciais separados**,
com o código comum vivendo em módulos.

Workspace é ótimo para: ambientes efêmeros de feature branch, testes, sandbox pessoal.

## Parte 3 — refaça do jeito certo
```
envs/dev/main.tf     → module "stack" { source = "../../modules/stack" }
envs/prod/main.tf    → module "stack" { source = "../../modules/stack" }
modules/stack/       → o código de verdade
```

## Anote
Essa conclusão reaparece no **Track 4 do plano de ramp-up multi-cloud** (state por tenant).
Escreva agora, com suas palavras, por que você separaria por diretório —
é resposta de entrevista.

## Critério de conclusão
Você fez das duas formas e sabe defender a segunda numa conversa técnica.

## Notas
