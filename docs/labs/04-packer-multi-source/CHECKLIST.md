# Checklist — 04-packer-multi-source

Artefato: `packer/templates/multi-base.pkr.hcl`

- [x] Escrever o template com dois `source` (ubuntu, alpine)
- [x] Provisioners com `only = [...]` separados por source
- [x] `post-processor "docker-tag"` usando `tags = ["${source.name}"]`
- [x] `task packer:build IMAGE=multi-base` produziu as duas imagens num único comando
- [x] `docker images multi-base` mostra `multi-base:ubuntu` e `multi-base:alpine`
- [x] Quebrei: um provisioner `apt-get` só, sem `only`, vi o Alpine falhar ("apt-get: not found", exit 127)
- [x] Li o erro completo e identifiquei em qual source falhou (docker.alpine)
- [x] Voltei para os provisioners separados
- [x] Notas preenchidas no README
