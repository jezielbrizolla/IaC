# Checklist — 06-tf-workflow-core

- [ ] Criar `main.tf` com provider docker + `docker_image` + `docker_container`
- [ ] `terraform init` OK
- [ ] `terraform fmt` / `terraform validate` limpos
- [ ] `terraform plan` revisado antes de aplicar
- [ ] `terraform apply -auto-approve` OK
- [ ] `curl localhost:8080` retorna a página do nginx
- [ ] Li o `terraform.tfstate` no editor e identifiquei `resources`, `attributes`, `serial`, `lineage`
- [ ] Comparei um atributo do state com `docker inspect lab06-web`
- [ ] Quebrei: apaguei o state com o container no ar, vi o plan querer recriar tudo
- [ ] Limpei o container manualmente (`docker rm -f`)
- [ ] `terraform destroy -auto-approve` deixou `docker ps -a` limpo
- [ ] Notas preenchidas no README
