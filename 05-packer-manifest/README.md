# Packer Lab 5 — golden image + manifest

**~1h · a ponte**

## Objetivo
Fazer o Packer registrar **qual** imagem ele produziu, em formato legível por máquina.

## O que escrever
```hcl
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true
}
```

## Depois do build
Abra o `manifest.json`. Entenda a estrutura: `builds[]`, cada um com `name`,
`artifact_id`, `custom_data`, mais o campo `last_run_uuid` no topo.
Rode o build de novo e veja que ele **acumula** entradas no array.

## Por que isto importa
Este JSON é o contrato entre Packer e Terraform. No Bloco 3 o Terraform vai lê-lo com
`jsondecode()` e subir exatamente esta imagem. Na AWS o equivalente é o Terraform buscar
a AMI com `data "aws_ami"` filtrando por uma tag que o Packer escreveu.

## Quebre isto
Rode 3 builds seguidos e depois tente pegar "a imagem certa" do manifest.
Você vai perceber que precisa **decidir uma regra**: último item do array?
Filtrar por `name`? Casar com `last_run_uuid`?
Essa decisão é o design da ponte — resolva aqui, não no Bloco 3.

## Critério de conclusão
`manifest.json` existe e você sabe qual campo contém o identificador da imagem.

## Notas
