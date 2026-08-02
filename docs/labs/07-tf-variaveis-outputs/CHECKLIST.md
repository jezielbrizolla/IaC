# Checklist — 07-tf-variaveis-outputs

Artefato: `terraform/stacks/web-basic/` (expande o stack do Lab 06)

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
