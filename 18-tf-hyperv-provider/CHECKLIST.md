# Checklist do 18-tf-hyperv-provider

- [ ] Golden image VHDX do lab 17 disponível
- [ ] Criar `main.tf` com provider `taliesins/hyperv`
- [ ] `terraform init` → provider baixado
- [ ] `terraform apply` → VM criada no Hyper-V a partir da golden image
- [ ] Verificar VM rodando: `Get-VM lab18-vm*`
- [ ] Escalar para 2 instâncias → só a segunda é criada
- [ ] Inspecionar `terraform.tfstate` → IDs do Hyper-V mapeados
- [ ] **Quebre:** deletar VM fora do TF → drift detectado no plan
- [ ] **Quebre:** reduzir count → entender destroy vs prevent_destroy
- [ ] `terraform destroy` → limpeza total

> Atualize os itens com `[x]` quando concluir.
