# Checklist — 05-packer-manifest

Artefato: `packer/templates/golden-manifest.pkr.hcl`

- [x] Adicionar `post-processor "manifest"` ao template
- [x] `task packer:build` / `packer build` gerou `manifest.json`
- [x] Rodei 2+ builds e confirmei que `builds[]` acumula entradas
- [x] Identifiquei os campos: `name`, `artifact_id`, `packer_run_uuid`, `custom_data`, `last_run_uuid`
- [x] Quebrei: 5 builds seguidos (1.0 a 5.0), decidi a regra pra pegar "a imagem certa"
- [x] Regra escolhida anotada nas Notas do README (`last_run_uuid` == `packer_run_uuid`, não posição do array)
- [x] Sei explicar por que este JSON é a ponte pro Terraform
