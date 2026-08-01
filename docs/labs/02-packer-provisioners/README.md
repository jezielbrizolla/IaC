# Packer Lab 2 — provisioners

**~1h · essencial**

## Objetivo
Instalar e configurar software dentro da imagem, em vez de só copiar uma base.

## Onde o código mora
| Arquivo | Papel |
|---|---|
| `packer/templates/ubuntu-nginx.pkr.hcl` | o template |
| `packer/scripts/install-nginx.sh` | provisionamento (compartilhado) |
| `packer/files/nginx/default.conf` | config copiada pra dentro da imagem |

Repare na separação: script e arquivo não moram junto do template. Qualquer
outra imagem que precise de nginx reusa o mesmo `install-nginx.sh` — a golden
image do bloco 4 vai fazer exatamente isso.

## A config do nginx
`packer/files/nginx/default.conf`:
```nginx
server {
    listen 80;
    server_name _;
    location / {
        return 200 'packer provisioner lab ok\n';
        add_header Content-Type text/plain;
    }
}
```
Config mínima que responde texto fixo — serve pra provar que foi *essa* config
que entrou na imagem, e não a padrão do pacote.

## O script de provisionamento
`packer/scripts/install-nginx.sh`:
```bash
#!/usr/bin/env bash
set -e
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
```
- `set -e` faz parar no primeiro comando que falhar. Sem isso, um `apt-get update`
  quebrado seguiria pro `install` com índice velho e mascararia o erro.
- `DEBIAN_FRONTEND=noninteractive` evita o apt travar esperando input — o
  container não tem terminal interativo.

## O template
```hcl
build {
  name    = "ubuntu-nginx"
  sources = ["source.docker.nginx"]

  provisioner "shell" {
    script = "scripts/install-nginx.sh"
  }

  provisioner "file" {
    source      = "files/nginx/default.conf"
    destination = "/etc/nginx/sites-available/default"
  }
}
```

Dois pontos que importam:
- **Paths são relativos a `packer/`**, não ao template. É de lá que o Taskfile
  invoca o `packer`, então `scripts/...` e `files/...` resolvem certo sempre —
  independente de onde você esteja no terminal.
- **A ordem dos provisioners é a ordem de execução.** Instalar primeiro, copiar
  a config depois; senão `/etc/nginx/sites-available/` nem existe. Não há grafo
  de dependência como no Terraform.

## Rodar
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

## Entenda
Este é o motivo do Packer existir: instalar no **build time**, uma vez, em vez
de a cada boot. Um `provisioner` do Terraform fazendo esse trabalho é o
anti-padrão clássico — o Terraform provisiona infra, não configura SO.

## Notas
