# Checklist do 16-ansible-windows-winrm

- [ ] Ansible + pywinrm instalados no WSL (`ansible --version`, `python -c "import winrm"`)
- [ ] VM Windows Server rodando (IP anotado)
- [ ] Criar `inventory.yml` com credenciais WinRM
- [ ] Criar `playbook.yml` com tasks de feature, hardening e validação
- [ ] `ansible ... win_ping` → pong (conectividade OK)
- [ ] `ansible-playbook` roda sem erros
- [ ] Confirmar: IIS instalado e rodando na VM
- [ ] Confirmar: `provisioned.txt` existe em `C:\Logs\Automation\`
- [ ] Confirmar: firewall habilitado, regra WinRM presente
- [ ] **Quebre:** rodar playbook 2x → observar idempotência (ok vs changed)
- [ ] **Quebre:** senha errada no inventory → HTTP 401
- [ ] **Quebre:** porta 5986 sem cert → falha SSL

> Atualize os itens com `[x]` quando concluir.
