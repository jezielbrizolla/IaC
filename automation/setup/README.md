# automation/setup — provisionamento da estação de trabalho

Automatiza o que [`docs/labs/00-setup/README.md`](../../docs/labs/00-setup/README.md)
pede manualmente: instala/valida Terraform, Packer e Docker Desktop, confere
WSL2+Ubuntu, a extensão do VS Code, o repositório git e a autenticação SSH com
o GitHub — tudo logado em console (colorido) e em arquivo.

É o próprio tema do repo aplicado a ele mesmo: se tudo aqui é sobre automatizar
infraestrutura, preparar a estação também devia ser automatizado.

## Rodar

Abra o **PowerShell como Administrador** (alguns `winget install` exigem
elevação). Da raiz do repo:

```powershell
task setup
```

Ou chamando o script direto, se precisar passar flags:

```powershell
powershell -ExecutionPolicy Bypass -File automation/setup/setup.ps1 -Push
```

### Flags

| Flag | O que faz |
|---|---|
| (nenhuma) | Roda todos os passos, atualiza o `CHECKLIST.md`, **nunca** commita ou dá push sozinho |
| `-Push` | Ao final, se o working tree estiver limpo, oferece rodar `git push -u origin main` (pede confirmação `s/N`) |
| `-Unattended` | Não faz nenhuma pergunta interativa — combine com `-Push` para push sem confirmação manual (útil em automação local) |
| `-SkipChecklistUpdate` | Não mexe no `00-setup/CHECKLIST.md` |

Exemplos:
```powershell
.\setup.ps1                          # setup normal, interativo
.\setup.ps1 -Push                    # ao final, pergunta se pode dar push
.\setup.ps1 -Push -Unattended        # push automático, sem perguntar
```

## O que ele faz (passo a passo)

| # | Passo | Ação |
|---|---|---|
| 1 | Pré-requisitos | Confirma `winget` disponível e sessão elevada |
| 2 | Terraform | Instala via `winget` se ausente, valida `terraform -version` |
| 3 | Packer | Instala via `winget` se ausente, valida `packer version` |
| 4 | Docker Desktop | Instala se ausente; testa `docker run hello-world` |
| 5 | WSL2 + Ubuntu | Confere se a distro Ubuntu existe em `wsl -l -v` |
| 6 | VS Code | Instala a extensão `hashicorp.terraform` se ausente |
| 7 | Git local | `git init` em `labs/` se ainda não existir, confere `.gitignore` |
| 8 | SSH | Testa `ssh -T git@github.com` no Windows **e** dentro do WSL Ubuntu |
| 9 | Git remote | Confere/cria o `origin`; só dá push com `-Push` explícito |

Cada passo é um arquivo em `steps/NN-Step-*.ps1` — leia/edite o que quiser
sem afetar os outros. `setup.ps1` só orquestra a ordem e agrega o resumo.

## Idempotência

Rodar o script várias vezes é seguro: cada passo primeiro **verifica** antes
de agir (não reinstala o que já está instalado, não sobrescreve remote
existente, não commita nada). Rodar de novo depois de resolver um `WARN`
manualmente (ex: abrir o Docker Desktop pela primeira vez) é o fluxo normal.

## Logs

Cada execução grava um arquivo novo em `logs/setup-YYYYMMDD-HHMMSS.log`
(ignorado pelo git — só o `.gitkeep` da pasta é versionado). O console
mostra a mesma informação colorida por nível:

- `OK` (verde) — passo validado
- `WARN` (amarelo) — precisa de ação manual sua (ex: abrir o Docker Desktop,
  instalar a distro do WSL, cadastrar a chave SSH no GitHub)
- `FAIL` (vermelho) — algo não funcionou mesmo depois da tentativa automática
- `STEP` (ciano) — cabeçalho de cada passo

Código de saída: `0` se tudo OK ou só WARN, `1` se algo FAIL — útil se você
quiser encadear isso num pipeline mais tarde.

## Atualização do CHECKLIST.md

Depois de rodar, o script marca `[x]` em `00-setup/CHECKLIST.md` nos itens
que ele conseguiu validar de verdade nesta execução (nunca desmarca algo já
marcado). O que precisa de ação manual (abrir o Docker Desktop, instalar
WSL, cadastrar chave SSH) fica como `WARN` no console/log e continua
`[ ]` até você resolver e rodar de novo.

## Segurança / o que ele NÃO faz

- Nunca faz `git push` sem a flag `-Push` explícita, e mesmo com `-Push`
  pede confirmação a menos que você também passe `-Unattended`.
- Nunca commita automaticamente — se houver mudanças não commitadas, o
  passo 9 avisa e para, não decide por você o que deveria virar commit.
- Nunca sobrescreve um `.gitignore` ou remote já existentes.
- Instalações via `winget` usam os IDs oficiais (`Hashicorp.Terraform`,
  `Hashicorp.Packer`, `Docker.DockerDesktop`) — nada de scripts de terceiros.

## Notas
