# Packer Lab 3 — variáveis e locals

**~1h**

## Objetivo
Parametrizar a imagem base e a versão do app.

## O que escrever
- `variable "base_image"` e `variable "app_version"` com `type` e `default`
- `locals` derivando o nome/tag final da imagem
- Um `variables.pkrvars.hcl` com valores

## Precedência (teste as quatro)
```
default  <  variables.pkrvars.hcl  <  -var  <  PKR_VAR_*
```
Rode `packer build -var 'app_version=2.0' .` e confirme com `packer inspect .`.

## Quebre isto
Declare uma `variable` sem `default` e sem passar valor. Veja o erro de validação.
Depois marque-a como `sensitive = true` e observe como ela aparece (ou não) no output.

## Critério de conclusão
`packer fmt` e `packer validate` limpos, e o mesmo template produz duas imagens
diferentes só mudando os vars.

## Notas
