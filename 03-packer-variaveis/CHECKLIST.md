# Checklist — 03-packer-variaveis

- [ ] Criar `docker.pkr.hcl` com `variable`, `locals`, `post-processor "docker-tag"`
- [ ] Criar `variables.pkrvars.hcl`
- [ ] Build com default (`app_version=1.0`)
- [ ] Build com `-var "app_version=2.0"`
- [ ] Build com `-var-file="variables.pkrvars.hcl"` (1.1)
- [ ] Build com `PKR_VAR_app_version` (3.0)
- [ ] `docker images meuapp` mostra as 4 tags
- [ ] `packer inspect .` rodado e entendido
- [ ] Quebrei: variável obrigatória sem default/valor → li o erro
- [ ] Testei `sensitive = true` e vi a diferença no output
- [ ] Notas preenchidas no README
