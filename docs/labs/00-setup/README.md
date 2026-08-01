# Setup — preparar a máquina

**~1h · uma vez só**

## Objetivo
Ter Packer, Terraform e Docker funcionando, e a pasta de labs versionada.

## Automatizado
Este é o único bloco todo manual do repo — o que é irônico num projeto sobre
automação. `automation/setup/` tem um orquestrador PowerShell que roda os
passos 1–6 abaixo sozinho (instala o que falta, valida o resto) e loga tudo
em console + arquivo. Da raiz do repo:
```powershell
task setup
```
Veja [`automation/setup/README.md`](../../../automation/setup/README.md) para as
flags (`-Push`, `-Unattended`) e o que cada passo faz. Os passos manuais abaixo
continuam valendo como referência — o script segue exatamente essa mesma lista.

## Passos
1. `winget install Hashicorp.Terraform` e `winget install Hashicorp.Packer`.
   Abra um terminal **novo** (o PATH só atualiza em sessão nova).
2. Docker Desktop com backend WSL2. Habilite a integração WSL nas settings.
   - Opcional: instale uma distro WSL como Ubuntu para usar terminal Linux.
     Exemplo: `wsl --install -d Ubuntu`
3. VS Code: extensão *HashiCorp Terraform*, com format on save.
4. `git init` na pasta `labs/`. O `.gitignore` já está lá.
5. SSH para o GitHub: gere/confirme a chave (`ssh-iac`) tanto no Windows/Git Bash
   quanto dentro do WSL Ubuntu se for usar os dois — são ambientes SSH separados.
   Valide com `ssh -T git@github.com` nos dois antes de tentar o push (ver `wsl-ssh-setup.sh`).
6. Crie o repositório remoto no GitHub, adicione o `origin` via SSH e faça o
   primeiro push (`git add`, `commit`, `git remote add origin`, `git push -u origin main`).

## Checklist
Veja `CHECKLIST.md` em `labs/00-setup/` para acompanhar o progresso do setup.
Repositório remoto: https://github.com/jezielbrizolla/IaC

## Critério de conclusão
```
terraform -version     # 1.x
packer version         # 1.x
docker run hello-world # "Hello from Docker!"
```

## Entenda
Abra o `.gitignore` de `labs/` e leia o comentário do fim. O `.terraform.lock.hcl`
**é versionado** — é ele que garante que você e o time resolvam a mesma versão de provider.
Muita gente ignora por engano e depois não entende por que o plan difere entre máquinas.

## Notas
