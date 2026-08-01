# Checklist — 03-packer-variaveis

Artefatos:
- `packer/templates/app-versioned.pkr.hcl`
- `packer/vars/app-versioned.pkrvars.hcl`

- [x] Escrever o template com `variable`, `locals`, `post-processor "docker-tag"`
- [x] Escrever `packer/vars/app-versioned.pkrvars.hcl`
- [x] Build com default (`app_version=1.0`)
- [x] Build com `-var "app_version=2.0"`
- [x] Build com `-var-file="vars/app-versioned.pkrvars.hcl"` (1.1)
- [x] Build com `PKR_VAR_app_version` (3.0)
- [x] `docker images meuapp` mostra as 4 tags
- [x] `packer inspect .` rodado e entendido
- [x] Quebrei: variável obrigatória sem default/valor → li o erro ("Unset variable"), numa cópia temporária, sem editar o template do repo
- [x] Testei `sensitive = true` e confirmei que o valor não aparece nem no build nem no `packer inspect` (`<unknown>`)
- [x] Notas preenchidas no README
