# Checklist — 01-packer-primeiro-build

- [x] Criar `docker.pkr.hcl` com `required_plugins` + `source "docker" "ubuntu"` + `build`
- [x] `packer init .` rodou sem erro
- [x] `packer fmt .` aplicado
- [x] `packer validate .` sem erros
- [x] `packer build .` produziu uma imagem
- [x] `docker image ls --all --filter "dangling=true"` mostra a imagem nova (aparece como `<untagged>` - normal, ainda sem tag)
- [x] Quebrei: comentei `required_plugins` **e** apaguei o cache de plugins, rodei `packer build .` e li o erro real ("The source docker is unknown by Packer")
- [ ] Sei explicar em 1 frase o que `commit = true` faz
- [ ] Notas preenchidas no README
