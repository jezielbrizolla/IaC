# Capstone Lab 1 — a ponte Packer → Terraform

**~1h**

## Objetivo
Packer produz a imagem, Terraform consome. Pipeline de duas etapas ponta a ponta.

## O que fazer
1. Copie o template do lab `05-packer-manifest` para cá. `packer build .` → `manifest.json`.
2. No Terraform:
```hcl
data "local_file" "manifest" {
  filename = "${path.module}/manifest.json"
}

locals {
  manifest = jsondecode(data.local_file.manifest.content)
  # aplique aqui a regra que você definiu no lab 05
  image    = local.manifest.builds[length(local.manifest.builds) - 1].artifact_id
}
```
3. O `docker_container` usa `local.image`.

## O teste que prova que funcionou
1. `apply` — container no ar com a imagem do Packer.
2. Mude o `setup.sh` do Packer (ex: outra página do nginx).
3. `packer build .` de novo.
4. `terraform plan` — ele deve propor **substituir** o container, porque a imagem mudou.
5. `apply` e confirme a mudança no navegador.

Esse ciclo — rebuild da imagem gera replace da instância — é literalmente o que acontece
com AMI + Auto Scaling Group na AWS. Você acabou de fazer local, em segundos.

## Quebre isto
Delete o `manifest.json` e rode `terraform plan`. Entenda por que o Terraform
não consegue nem planejar: o `data` source falha antes de qualquer outra coisa.
Pense em como isso se comportaria num pipeline de CI.

## Critério de conclusão
Um comando de Packer + um de Terraform, e a mudança aparece no navegador.

## Notas
