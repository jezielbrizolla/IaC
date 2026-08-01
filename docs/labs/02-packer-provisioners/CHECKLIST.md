# Checklist — 02-packer-provisioners

- [x] Criar `nginx.conf`
- [x] Criar `docker.pkr.hcl` com `provisioner "shell" { inline = [...] }` + `provisioner "file"`
- [x] `packer init .` / `packer build .` OK
- [x] Container rodando: `docker run -d --name nginx-lab -p 8080:80 <imagem> nginx -g "daemon off;"`
- [x] `curl localhost:8080` retorna o texto de teste
- [x] `docker rm -f nginx-lab` (limpou)
- [ ] Criar `setup.sh` e migrar `inline` → `script = "setup.sh"`
- [ ] Rebuild com script externo funcionou igual
- [ ] Quebrei: inverti a ordem `file` antes de `shell`, li o erro, voltei ao normal
- [ ] Notas preenchidas no README
