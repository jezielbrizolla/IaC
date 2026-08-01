# Terraform Lab 5 — módulos

**~1h**

## Objetivo
Empacotar e reutilizar.

## Estrutura a criar
```
10-tf-modulos/
├── main.tf              # chama o módulo duas vezes
├── outputs.tf
└── modules/
    └── webapp/
        ├── main.tf      # container + rede + volume
        ├── variables.tf
        └── outputs.tf
```

## O que fazer
1. Mova o que você fez nos labs anteriores para `modules/webapp/`.
2. No root, chame `module "app_a"` e `module "app_b"` com inputs diferentes
   (nomes e portas diferentes).
3. Exponha um output do módulo no output do root: `module.app_a.url`.

## Entenda `source`
Conheça os três formatos (o terceiro só para ler a sintaxe, sem aplicar):
- local: `source = "./modules/webapp"`
- git: `source = "git::https://github.com/user/repo.git//modules/webapp?ref=v1.0.0"`
- registry: `source = "terraform-aws-modules/vpc/aws"` + `version = "~> 5.0"`

**Sempre pinar versão** em git (`?ref=`) e registry (`version =`).
Módulo sem pin é build não-reproduzível.

## Quebre isto
Adicione uma nova chamada de módulo e rode `plan` sem `init` antes.
Compare com adicionar só um recurso dentro de um módulo já inicializado —
entenda por que num caso o `init` é obrigatório e no outro não.

## Critério de conclusão
Duas apps rodando em portas diferentes, saindo do mesmo módulo.

## Notas
