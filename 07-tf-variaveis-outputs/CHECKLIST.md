# Checklist — 07-tf-variaveis-outputs

- [ ] Criar `variables.tf` com `container_name`, `external_port` (com `validation`), `labels`
- [ ] Criar `main.tf` usando `locals.full_name`
- [ ] Criar `outputs.tf` com `url` e `container_id`
- [ ] Criar `terraform.tfvars` com `external_port`
- [ ] Apply usando `terraform.tfvars`
- [ ] Apply sobrescrevendo com `-var`
- [ ] Apply sobrescrevendo com `TF_VAR_external_port`
- [ ] `terraform output url` funcionando
- [ ] Quebrei: `external_port=80`, li a mensagem de validação, reescrevi o `error_message`
- [ ] Sei explicar a diferença entre `variable` e `locals`
- [ ] Notas preenchidas no README
