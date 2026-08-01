# Checklist — 14-capstone-empacotar

- [ ] Criar `build.ps1` (packer init/validate/build → terraform init/plan/apply)
- [ ] Criar `destroy.ps1` (terraform destroy + limpeza de imagens/manifest/tfplan)
- [ ] `README.md` do capstone: o que é, por quê, como rodar em 3 comandos
- [ ] Diagrama mermaid incluído
- [ ] `.terraform.lock.hcl` confirmado como versionado (`git check-ignore -v` vazio)
- [ ] Versões pinadas (provider, plugin Packer, `required_version` Terraform)
- [ ] Seção "próximos passos: AWS" com a tabela de tradução
- [ ] `.\build.ps1` rodou do zero e funcionou
- [ ] `.\destroy.ps1` limpou tudo (conferido com `docker ps -a` e `docker images`)
- [ ] Pedi pra alguém (ou eu mesmo, dias depois) seguir só o README sem ajuda
- [ ] Commit + push do capstone
- [ ] Notas preenchidas no README
