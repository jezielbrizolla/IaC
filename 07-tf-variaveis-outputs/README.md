# Terraform Lab 2 — variáveis, tipos e outputs

**~1h**

## Objetivo
Parametrizar a stack e expor informação de volta.

## O que escrever
- `variable "container_name"` (string) e `variable "external_port"` (number) com
  bloco `validation` — ex: porta entre 1024 e 65535
- `variable "labels"` do tipo `map(string)`
- `output "url"` e `output "container_id"`
- Um `terraform.tfvars`
- Pelo menos um `locals` (ex: nome composto com prefixo de ambiente)

## Precedência (teste as quatro)
```
default  <  terraform.tfvars  <  TF_VAR_external_port  <  -var
```

## Quebre isto
Passe uma porta inválida (ex: `80`) e leia a mensagem do `validation`.
Escreva a `error_message` de forma que **você mesmo** entenderia daqui a 6 meses.

## Entenda
`variable` = entrada do módulo, vem de fora. `locals` = valor derivado, calculado dentro.
Se você tem uma `variable` com `default` que ninguém nunca sobrescreve, era `locals`.

## Critério de conclusão
`terraform output url` imprime uma URL que abre no navegador.

## Notas
