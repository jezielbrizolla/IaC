# Setup — preparar a máquina

**~1h · uma vez só**

## Objetivo
Ter Packer, Terraform, Docker e o `task` (runner do Taskfile) funcionando, e a
pasta de labs versionada.

## Automatizado
Este é o único bloco todo manual do repo — o que é irônico num projeto sobre
automação. `automation/setup/` tem um orquestrador PowerShell de 10 passos que
roda tudo abaixo sozinho (instala o que falta, valida o resto) e loga tudo em
console + arquivo. Da raiz do repo:
```powershell
task setup
```

> Se `task` ainda não existir na sua máquina (é o próprio passo 10 do
> orquestrador), rode uma vez direto pelo PowerShell:
> ```powershell
> powershell -ExecutionPolicy Bypass -File automation/setup/setup.ps1
> ```
> Depois disso `task setup` já funciona normalmente.

Veja [`automation/setup/README.md`](../../../automation/setup/README.md) para as
flags (`-Push`, `-Unattended`) e o que cada passo faz. Os passos manuais abaixo
continuam valendo como referência — o script segue exatamente essa mesma lista,
mais a instalação do `task`.

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
   Valide com `ssh -T git@github.com` nos dois antes de tentar o push (ver
   [`automation/setup/wsl-ssh-setup.sh`](../../../automation/setup/wsl-ssh-setup.sh)).
6. Crie o repositório remoto no GitHub, adicione o `origin` via SSH e faça o
   primeiro push (`git add`, `commit`, `git remote add origin`, `git push -u origin main`).
7. `winget install Task.Task` — o runner do `Taskfile.yml`, o ponto de entrada
   único do repo (ver [README raiz](../../../README.md)). Abra um terminal
   **novo** e confirme com `task --version`.

## Checklist
Veja a seção `### 00-setup` em [`TODO.md`](../../../TODO.md) (raiz do repo)
para acompanhar o progresso do setup — `task setup` marca os itens
automaticamente conforme valida cada passo.
Repositório remoto: <https://github.com/jezielbrizolla/IaC>

## Critério de conclusão
```text
terraform -version     # 1.x
packer version         # 1.x
docker run hello-world # "Hello from Docker!"
task --version          # 3.x
```

## Entenda
Abra o `.gitignore` de `labs/` e leia o comentário do fim. O `.terraform.lock.hcl`
**é versionado** — é ele que garante que você e o time resolvam a mesma versão de provider.
Muita gente ignora por engano e depois não entende por que o plan difere entre máquinas.

## Notas
