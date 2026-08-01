# Checklist — 04-packer-multi-source

- [ ] Criar `docker.pkr.hcl` com dois `source` (ubuntu, alpine)
- [ ] Provisioners com `only = [...]` separados por source
- [ ] `post-processor "docker-tag"` usando `${build.name}`
- [ ] `packer build .` produziu as duas imagens num único comando
- [ ] `docker images meuapp` mostra `docker.ubuntu` e `docker.alpine`
- [ ] Quebrei: um provisioner `apt-get` só, sem `only`, vi o Alpine falhar
- [ ] Li o erro completo e identifiquei em qual source falhou
- [ ] Voltei para os provisioners separados
- [ ] Notas preenchidas no README
