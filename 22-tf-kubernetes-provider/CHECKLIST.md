# Checklist do 22-tf-kubernetes-provider

- [ ] Cluster rodando e kubectl configurado
- [ ] Criar `main.tf` com provider kubernetes + namespaces via for_each
- [ ] `terraform init` → provider baixado
- [ ] `terraform apply` → namespaces + quotas + policies criados
- [ ] `kubectl get namespaces -l managed-by=terraform` → dev e prod
- [ ] ResourceQuota diferente em dev vs prod (verificar)
- [ ] NetworkPolicy deny-all apenas em prod
- [ ] Adicionar namespace "staging" ao mapa → `plan` cria só o novo
- [ ] **Quebre:** deletar namespace via kubectl → drift no plan
- [ ] **Quebre:** recurso manual dentro do namespace → TF não sabe
- [ ] `terraform destroy` → limpeza completa

> Atualize os itens com `[x]` quando concluir.
