# Checklist — 02-packer-provisioners

Artefatos:
- `packer/templates/ubuntu-nginx.pkr.hcl`
- `packer/scripts/install-nginx.sh`
- `packer/files/nginx/default.conf`

- [x] Escrever a config do nginx
- [x] Escrever o template com `provisioner "shell" { inline = [...] }` + `provisioner "file"`
- [x] `packer init` / `packer build` OK
- [x] Container rodando e servindo a config própria
- [x] Resposta HTTP retorna o texto de teste
- [x] Container de teste removido
- [x] Migrar `inline` → `script` externo
      <br>_Nota: o script de refactor foi escrito por mim (JZ) — regex + here-string em
      PowerShell — mas quem aterrissou o arquivo na estrutura nova foi o Claude,
      durante a reestruturação do repo. O conceito (extrair para script reutilizável)
      foi entendido; a execução final veio junto da migração._
- [x] Rebuild com script externo funcionou igual
- [x] Quebrei: inverti a ordem `file` antes de `shell`, li o erro ("must be a directory" — não o "no such file" esperado), voltei ao normal via `git checkout`
- [x] Notas preenchidas no README
