# Checklist do 21-k8s-vault-postgres

- [ ] Helm instalado
- [ ] Vault instalado via Helm (dev mode + injector)
- [ ] PostgreSQL instalado via Helm (namespace database)
- [ ] Segredo criado no Vault (`secret/lab21/db`)
- [ ] Kubernetes auth habilitado no Vault
- [ ] Policy + role criados para `lab21-sa`
- [ ] Criar `app-with-vault.yml` com annotations de Vault inject
- [ ] Pod do app roda e mostra "DB OK" nos logs
- [ ] `cat /vault/secrets/db` mostra credenciais injetadas pelo sidecar
- [ ] **Quebre:** policy deny → pod em loop
- [ ] **Quebre:** ServiceAccount errado → auth falha
- [ ] **Quebre:** deletar segredo → sidecar falha no refresh
- [ ] Limpeza: `helm uninstall`, `kubectl delete namespace`

> Atualize os itens com `[x]` quando concluir.
