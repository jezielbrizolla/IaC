# Checklist do 15-packer-hyperv-windows

- [ ] Virtual Switch externo criado no Hyper-V (`LabSwitch`)
- [ ] ISO do Windows Server 2022 Evaluation baixada
- [ ] Criar `variables.pkrvars.hcl` com paths e credenciais
- [ ] Criar `win2022.pkr.hcl` com builder `hyperv-iso`
- [ ] Criar `Autounattend.xml` com partições UEFI + auto-login + WinRM
- [ ] `packer init .` → plugins baixados
- [ ] `packer validate -var-file="variables.pkrvars.hcl" .` → sem erros
- [ ] `packer build -var-file="variables.pkrvars.hcl" .` → build inicia
- [ ] Observar no Hyper-V Manager: VM criada, Windows instalando sozinho
- [ ] WinRM conecta e provisioner PowerShell roda com sucesso
- [ ] Build completa → imagem exportada em `output-win2022/`
- [ ] **Quebre:** remover Autounattend dos cd_files → timeout de WinRM
- [ ] **Quebre:** dessincronizar senha entre Autounattend e variables → falha de auth
- [ ] Limpeza: remover VM do Hyper-V e pasta de output

> Atualize os itens com `[x]` quando concluir.
