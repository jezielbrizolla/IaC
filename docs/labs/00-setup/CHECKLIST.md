# Checklist do 00-setup

Este arquivo registra o que já foi concluído no lab `00-setup`.

- [x] Instalar Terraform (`winget install Hashicorp.Terraform`)
- [x] Instalar Packer (`winget install Hashicorp.Packer`)
- [x] Instalar Docker Desktop com backend WSL2
- [x] Habilitar integração WSL no Docker Desktop
- [x] Instalar extensão HashiCorp Terraform no VS Code
- [x] Inicializar repositório Git na pasta `labs/`
- [x] Configurar chave SSH `ssh-iac` no Ubuntu WSL
- [x] Configurar chave SSH `ssh-iac` no PowerShell/Windows
- [x] Validar `ssh -T git@github.com` no Windows/Git Bash → autenticou como `jezielbrizolla`
- [x] Validar `ssh -T git@github.com` dentro do WSL Ubuntu → autenticou como `jezielbrizolla`
- [x] Criar repositório remoto no GitHub — https://github.com/jezielbrizolla/IaC
- [x] Adicionar `origin` (SSH) em `labs/` apontando para `git@github.com:jezielbrizolla/IaC.git`
- [x] Fazer commit inicial em `labs/`
- [x] Enviar o primeiro push para `origin main`
- [x] Validar `terraform -version` → 1.15.8
- [x] Validar `packer version` → 1.16.0
- [x] Validar `docker run hello-world`

## Correções aplicadas nesta revisão
- `wsl-ssh-setup.sh`: `chmod 600 ~/.ssh/config` quebrava com `set -e` se o arquivo
  ainda não existisse. Agora só roda o `chmod` se o arquivo existir (idem para a chave
  privada `ssh-iac`, que também precisa estar em 600).

> Atualize os itens com `[x]` quando concluir.
