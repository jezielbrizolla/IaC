# Checklist — 12-capstone-ponte

- [ ] Criar `nginx.conf`, `setup.sh`, `docker.pkr.hcl` (com `post-processor "manifest"`)
- [ ] `packer build .` gerou `manifest.json`
- [ ] Criar `terraform/main.tf` lendo o manifest via `data "local_file"` + `jsondecode()`
- [ ] `terraform apply` subiu o container com a imagem do Packer
- [ ] `curl localhost:8080` retorna `capstone v1`
- [ ] Editei `nginx.conf`, rebuild do Packer, `terraform plan` propôs substituir
- [ ] `terraform apply` e confirmei `capstone v2` no navegador
- [ ] Quebrei: apaguei `manifest.json`, li o erro do `data` source
- [ ] Restaurei o manifest e voltei a funcionar
- [ ] `terraform destroy` limpo
- [ ] Notas preenchidas no README
