# Checklist — 06-tf-workflow-core

Artefato: `terraform/stacks/web-basic/main.tf`

- [x] Escrever o stack com `terraform{}` + `provider "docker"` + `docker_image` + `docker_container`
- [x] `terraform -chdir=... init` OK — provider `kreuzwerker/docker v3.9.0`, lock file criado
- [x] `terraform -chdir=... fmt` / `validate` limpos
- [x] `terraform -chdir=... plan` revisado antes de aplicar (`2 to add, 0 to change, 0 to destroy`)
- [x] `terraform -chdir=... apply -auto-approve` OK
- [x] `curl localhost:8080` retorna a página do nginx (StatusCode 200)
- [x] Li o `terraform.tfstate` e identifiquei `resources`, `attributes`, `serial`, `lineage`
- [x] Comparei o `id` do state com `docker inspect lab06-web` — idênticos
- [x] Quebrei: apaguei o state com o container no ar, vi o plan querer recriar tudo (`2 to add`)
- [x] Restaurei o backup do state — `plan` voltou a `No changes`
- [x] `terraform destroy -auto-approve` deixou `docker ps -a` limpo
- [x] Notas preenchidas no README
