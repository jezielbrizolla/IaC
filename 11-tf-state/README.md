# Terraform Lab 6 — state na prática

**~1h · o que separa júnior de sênior**

## Objetivo
Operar o state com confiança. É o lab mais denso do bloco — reserve a sessão longa.

## Parte 1 — inspeção
```
terraform state list
terraform state show docker_container.app
```

## Parte 2 — import
1. Crie um container **fora** do Terraform:
   `docker run -d --name orfao -p 9090:80 nginx`
2. Escreva o `resource` correspondente no `.tf` (só o bloco, sem apply).
3. `terraform import docker_container.orfao <container_id>`
4. `terraform plan` — ajuste a config até o plan ficar **vazio**.
   Esse ajuste é o exercício real: você está descobrindo o estado verdadeiro do recurso.

> Alternativa moderna: bloco `import { to = ..., id = ... }` no código, e
> `terraform plan -generate-config-out=gerado.tf`. Vale testar as duas formas.

## Parte 3 — drift
1. `docker stop orfao` (mudança fora do Terraform)
2. `terraform plan` — o Terraform detecta e propõe corrigir
3. `terraform plan -refresh-only` — veja a diferença: aqui ele só reconcilia o state
   com a realidade, sem propor mudar a realidade

## Parte 4 — mv e moved
1. Renomeie `docker_container.app` para `docker_container.web` no código.
2. `plan` → ele quer **destruir e criar**. Cancele.
3. Resolva de duas formas:
   - `terraform state mv docker_container.app docker_container.web` (imperativo, não versionado)
   - bloco `moved { from = ..., to = ... }` (declarativo, versionado — **prefira este**)

## Parte 5 — rm
`terraform state rm` tira do state **sem destruir** o recurso. Faça, confirme com
`docker ps` que o container continua vivo, e entenda quando isso é útil
(migrar um recurso entre configs) e quando é perigoso (esquecer que ele existe e
continuar pagando por ele).

## Critério de conclusão
Você fez um `import`, chegou a plan vazio, e sabe explicar a diferença entre
`state rm` e `destroy` sem pensar.

## Notas
