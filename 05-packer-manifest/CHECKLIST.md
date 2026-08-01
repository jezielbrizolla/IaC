# Checklist — 05-packer-manifest

- [ ] Adicionar `post-processor "manifest"` ao template
- [ ] `packer build .` gerou `manifest.json`
- [ ] Rodei 2+ builds e confirmei que `builds[]` acumula entradas
- [ ] Identifiquei os campos: `name`, `artifact_id`, `custom_data`, `last_run_uuid`
- [ ] Quebrei: 3 builds seguidos, decidi a regra pra pegar "a imagem certa"
- [ ] Regra escolhida anotada nas Notas do README
- [ ] Sei explicar por que este JSON é a ponte pro Terraform
