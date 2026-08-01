# Checklist — 10-tf-modulos

- [ ] Criar `modules/webapp/` com `main.tf`, `variables.tf`, `outputs.tf`
- [ ] Criar `main.tf` (root) chamando `module "app_a"` e `module "app_b"`
- [ ] Criar `outputs.tf` (root) expondo `module.app_a.url` / `module.app_b.url`
- [ ] `terraform init` OK (baixou/registrou os módulos)
- [ ] `terraform apply` — duas apps no ar
- [ ] `curl localhost:8091` e `curl localhost:8092` respondem
- [ ] Testei os 3 formatos de `source` (local aplicado, git/registry só lidos)
- [ ] Quebrei: módulo novo sem `init` antes → erro
- [ ] Testei: recurso novo dentro de módulo existente sem `init` → funciona
- [ ] `terraform destroy` limpo
- [ ] Notas preenchidas no README
