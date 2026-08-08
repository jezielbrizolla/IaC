# Packer Lab 2 — provisioners

**~1h · essencial**

## Objetivo
Instalar e configurar software dentro da imagem, em vez de só copiar uma base.

## Teoria

**Provisioner é o que muda o conteúdo da imagem.** No Lab 01 o build só
pegou uma base e commitou — imagem idêntica à origem, sem valor. O
`provisioner` é o passo que roda *dentro* da máquina durante o build:
instala pacote, copia arquivo, aplica configuração. É onde a imagem deixa de
ser "Ubuntu" e passa a ser "Ubuntu com nginx configurado do nosso jeito".

**Build time vs boot time — o motivo do Packer existir.** A alternativa a
construir a imagem é configurar cada máquina depois que ela sobe. Isso custa
tempo em *todo* boot, e cada máquina pode divergir (o repositório mudou,
a versão do pacote mudou, a rede falhou no meio). Instalar no build time
acontece **uma vez**; o resultado é congelado na imagem, e toda máquina que
nasce dela é idêntica e sobe pronta.

> É por isso que usar `provisioner` do *Terraform* pra instalar software é
> anti-padrão clássico: Terraform provisiona **infra** (a máquina existe,
> a rede existe); configurar o SO é trabalho de Packer (no build) ou Ansible
> (depois). Cada ferramenta na sua camada.

**Dois tipos de provisioner neste lab:**

- **`shell`** — roda comandos dentro da imagem. Aqui via `script = "..."`
  (arquivo externo) em vez de `inline = [...]`. A diferença é reuso: o mesmo
  `install-nginx.sh` serve pra qualquer imagem que precise de nginx, e a
  golden image do Bloco 4 vai reaproveitar exatamente esse arquivo.
- **`file`** — copia um arquivo do seu disco pra dentro da imagem. É como a
  configuração entra sem você ter que gerar ela com `echo` dentro de um shell
  script (frágil e ilegível).

**A ordem dos provisioners é a ordem de execução — literalmente.** O Packer
executa de cima pra baixo, e **não existe grafo de dependência** aqui. Isso
contrasta com o Terraform (Lab 08), que descobre sozinho o que vem antes
analisando as referências entre recursos. No Packer, se você copiar a config
do nginx antes de instalar o nginx, o diretório de destino não existe e o
build quebra. Quem ordena é você.

## O que vamos criar

| Arquivo | Papel |
|---|---|
| `packer/templates/ubuntu-nginx.pkr.hcl` | o template |
| `packer/scripts/install-nginx.sh` | provisionamento (compartilhado) |
| `packer/files/nginx/default.conf` | config copiada pra dentro da imagem |

Repare na separação: script e arquivo **não** moram junto do template.
Qualquer outra imagem que precise de nginx reusa o mesmo `install-nginx.sh`.

Dois detalhes do conteúdo que valem entender antes de rodar:

- No script, `set -e` faz parar no primeiro comando que falhar. Sem isso, um
  `apt-get update` quebrado seguiria pro `install` com índice velho e
  mascararia o erro. E `DEBIAN_FRONTEND=noninteractive` evita o apt travar
  esperando input — o container não tem terminal interativo.
- Na config, `default_type` **define** o Content-Type da resposta.
  `add_header Content-Type ...` seria diferente: `add_header` **acrescenta**
  um header, não substitui — o resultado viraria
  `application/octet-stream,text/plain` (o `return` já manda `octet-stream`
  por padrão), e o cliente trataria o corpo como binário. Foi exatamente esse
  bug que apareceu na primeira versão deste lab — ver Notas.

## Passo 1 — criar os três arquivos

Um script, cria tudo. Rode da raiz `labs/`:

```powershell
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). Set-Content puro gravaria CRLF, e script .sh com CRLF
# quebra dentro do container Linux com "bad interpreter: /usr/bin/env^M".
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

Write-RepoFile "packer/scripts/install-nginx.sh" @'
#!/usr/bin/env bash
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
'@

Write-RepoFile "packer/files/nginx/default.conf" @'
server {
    listen 80;
    server_name _;

    location / {
        # default_type DEFINE o Content-Type da resposta.
        # `add_header Content-Type ...` seria errado aqui: add_header ACRESCENTA
        # um header, não substitui — o resultado vira
        # "application/octet-stream,text/plain" (o octet-stream é o default do
        # `return`), e clientes tratam o corpo como binário.
        default_type text/plain;
        return 200 'packer provisioner lab ok\n';
    }
}
'@

Write-RepoFile "packer/templates/ubuntu-nginx.pkr.hcl" @'
# Imagem Ubuntu + nginx, servindo uma config própria.
#
# Paths relativos aqui dentro são resolvidos a partir de packer/,
# que é o diretório onde o Taskfile invoca o packer.

packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

source "docker" "nginx" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name    = "ubuntu-nginx"
  sources = ["source.docker.nginx"]

  # Instalação via script externo em vez de inline: o mesmo script é
  # reaproveitado por outras imagens (ex: a golden image do bloco 4).
  provisioner "shell" {
    script = "scripts/install-nginx.sh"
  }

  # Só depois do nginx instalado é que /etc/nginx/... existe.
  # Provisioners rodam na ordem declarada — não há grafo de dependência aqui.
  provisioner "file" {
    source      = "files/nginx/default.conf"
    destination = "/etc/nginx/sites-available/default"
  }
}
'@
```

> **Por que `scripts/...` e não `packer/scripts/...` dentro do template:**
> paths no `.pkr.hcl` são relativos a `packer/`, porque é de lá que o
> Taskfile invoca o `packer` (`dir: '{{.PACKER_DIR}}'`). Assim resolvem certo
> sempre, independente de onde você esteja no terminal.

## Passo 2 — rodar

```powershell
task packer:build IMAGE=ubuntu-nginx
task packer:test  IMAGE=ubuntu-nginx
```

`packer:test` sobe um container, bate via HTTP, compara o corpo com o esperado
e derruba o container no fim — inclusive se o teste falhar.

## Quebre isto

Inverta a ordem: ponha o `provisioner "file"` **antes** do `shell`, e rode
`task packer:build IMAGE=ubuntu-nginx`. O destino ainda não existe nesse ponto
do build. Leia o erro e devolva à ordem correta.

## Critério de conclusão
`task packer:test IMAGE=ubuntu-nginx` passa — a imagem tem nginx instalado e
servindo a config do repo.

## Limpeza

```powershell
task clean
```

## Notas

- **O "Quebre isto" não deu o erro que eu esperava.** Invertendo `file` antes
  de `shell`, achei que ia ver algo tipo "no such file or directory". Veio
  `... must be a directory` — porque o `provisioner "file"` do Docker não cria
  o caminho de destino sozinho; se `/etc/nginx/sites-available/` ainda não
  existe (porque o nginx não foi instalado), ele recusa de um jeito ambíguo em
  vez de simplesmente reclamar que a pasta não existe.
- **A config do nginx tinha um bug real na primeira versão** (`add_header
  Content-Type` em vez de `default_type`) — `add_header` acrescenta, não
  substitui, e a resposta saía como binário em vez de texto. Só apareceu
  porque o script de teste (`packer:test`) checava o corpo da resposta como
  string e quebrou com um erro completamente diferente (`.Content` vindo como
  `Byte[]`). Foi um bug puxando outro.
- **`task` só sobe diretórios procurando o `Taskfile.yml`, nunca desce.** De
  dentro de `IaC/` (a pasta *acima* de `labs/`) ele não acha nada — sempre
  preciso estar dentro de `labs/` ou de algum subdiretório dela.
