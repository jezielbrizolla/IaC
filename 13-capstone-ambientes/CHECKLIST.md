# Checklist — 13-capstone-ambientes

- [ ] Criar `main.tf` usando `terraform.workspace`
- [ ] Criar `dev.tfvars` e `prod.tfvars`
- [ ] `terraform workspace new dev` / `new prod`
- [ ] Apply em `dev` com `dev.tfvars`
- [ ] Apply em `prod` com `prod.tfvars`
- [ ] Confirmei `terraform.tfstate.d/` com um state por workspace
- [ ] Reproduzi a armadilha: selecionei `prod` e apliquei `dev.tfvars` por engano
- [ ] Entendi por que não há barreira estrutural entre workspaces
- [ ] Criei a estrutura `modules/stack/` + `envs/dev/` + `envs/prod/`
- [ ] Apply funcionando nos dois diretórios separados
- [ ] Conclusão sobre "por que diretório > workspace para prod/non-prod" anotada nas Notas
- [ ] Limpeza completa (destroy nos dois modelos, workspaces deletados)
- [ ] Notas preenchidas no README
