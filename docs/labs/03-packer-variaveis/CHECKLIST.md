# Checklist — 03-packer-variaveis

Artefatos:
- `packer/templates/app-versioned.pkr.hcl`
- `packer/vars/app-versioned.pkrvars.hcl`

- [ ] Escrever o template com `variable`, `locals`, `post-processor "docker-tag"`
- [ ] Escrever `packer/vars/app-versioned.pkrvars.hcl`
- [ ] Build com default (`app_version=1.0`)
- [ ] Build com `-var "app_version=2.0"`
- [ ] Build com `-var-file="vars/app-versioned.pkrvars.hcl"` (1.1)
- [ ] Build com `PKR_VAR_app_version` (3.0)
- [ ] `docker images meuapp` mostra as 4 tags
- [ ] `packer inspect .` rodado e entendido
- [ ] Quebrei: variável obrigatória sem default/valor → li o erro (numa cópia temporária, sem editar o template do repo)
- [ ] Testei `sensitive = true` e confirmei que o valor não aparece nem no build nem no `packer inspect`
- [ ] Notas preenchidas no README
