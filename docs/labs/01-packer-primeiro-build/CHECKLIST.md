# Checklist — 01-packer-primeiro-build

Artefato: `packer/templates/ubuntu-base.pkr.hcl`

- [x] Escrever o template com `required_plugins` + `source "docker"` + `build`
- [x] `task packer:init` — plugin baixado
- [x] `packer fmt` aplicado
- [x] `task packer:validate IMAGE=ubuntu-base` sem erros
- [x] `task packer:build IMAGE=ubuntu-base` produziu uma imagem
- [x] `docker image ls --all --filter "dangling=true"` mostra a imagem (aparece como `<untagged>` — normal, ainda sem tag; o lab 04 fecha isso)
- [x] Quebrei: comentei `required_plugins` **e** isolei o cache de plugins, rodei o build e li o erro real ("The source docker is unknown by Packer")
- [ ] Sei explicar em 1 frase o que `commit = true` faz
- [ ] Notas preenchidas no README
