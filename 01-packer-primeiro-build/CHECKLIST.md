# Checklist — 01-packer-primeiro-build

- [ ] Criar `docker.pkr.hcl` com `required_plugins` + `source "docker" "ubuntu"` + `build`
- [ ] `packer init .` rodou sem erro
- [ ] `packer fmt .` aplicado
- [ ] `packer validate .` sem erros
- [ ] `packer build .` produziu uma imagem
- [ ] `docker images` mostra a imagem nova
- [ ] Quebrei: apaguei `required_plugins`, rodei `packer build .` e li o erro
- [ ] Sei explicar em 1 frase o que `commit = true` faz
- [ ] Notas preenchidas no README
