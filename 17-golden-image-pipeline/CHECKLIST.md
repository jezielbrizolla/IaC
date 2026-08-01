# Checklist do 17-golden-image-pipeline

- [ ] Copiar `Autounattend.xml` do lab 15
- [ ] Criar `golden.pkr.hcl` com provisioners PowerShell + Ansible + Sysprep
- [ ] Criar `playbook-golden.yml` (features + hardening + updates)
- [ ] `packer init .` e `packer build` → build completo
- [ ] Ansible provisiona via WinRM durante o build
- [ ] Sysprep executa e VM desliga sozinha
- [ ] `golden-manifest.json` gerado
- [ ] **Quebre:** sem Sysprep → SID duplicado
- [ ] **Quebre:** timeout curto → perda de conexão no reboot

> Atualize os itens com `[x]` quando concluir.
