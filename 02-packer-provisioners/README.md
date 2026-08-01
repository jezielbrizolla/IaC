# Packer Lab 2 — provisioners

**~1h · essencial**

## Objetivo
Instalar e configurar software dentro da imagem, em vez de só copiar uma base.

## O que escrever
1. `provisioner "shell"` com `inline = [...]` instalando nginx.
2. Migrar para `script = "setup.sh"` (crie o arquivo).
3. `provisioner "file"` copiando um `nginx.conf` local para dentro da imagem.

## Quebre isto
Inverta a ordem: ponha o `file` provisioner **antes** do `shell` que instala o nginx,
copiando para um diretório que ainda não existe. Leia o erro.
Provisioners rodam na ordem declarada — não há resolução automática de dependência
como no Terraform.

## Critério de conclusão
Subir um container a partir da imagem e ver a sua config sendo servida em localhost:8080.

## Entenda
Este é o motivo do Packer existir: instalar no **build time**, uma vez, em vez de
a cada boot. Um `provisioner` do Terraform fazendo esse trabalho é o anti-padrão clássico.

## Notas
