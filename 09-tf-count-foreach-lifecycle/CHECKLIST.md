# Checklist — 09-tf-count-foreach-lifecycle

- [ ] Criar `main.tf` com a imagem compartilhada
- [ ] Criar `count.tf`, apply com 3 containers
- [ ] Remover `"b"` da lista, `plan` (sem aplicar) e ler o destroy/recreate indevido
- [ ] `terraform destroy` e trocar para `foreach.tf`
- [ ] Apply com `for_each`, remover `"b"`, `plan` e confirmar que só ele é destruído
- [ ] Diferença count vs for_each anotada nas Notas
- [ ] Testar `create_before_destroy = true` e ver a ordem inverter no plan
- [ ] Testar `ignore_changes = [image]`
- [ ] Testar `prevent_destroy = true` e ler o erro do destroy (depois remover)
- [ ] `terraform destroy` limpo no final
- [ ] Notas preenchidas no README
