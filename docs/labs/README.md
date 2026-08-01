# Labs — material didático

Cada pasta aqui tem `README.md` (o plano do lab) e `CHECKLIST.md` (o progresso).
**Nenhum código mora aqui** — o código que os labs produzem vai para o shape de
repo real na raiz (`packer/`, `terraform/`, `ansible/`, `k8s/`).

`task status` mostra o progresso de todos os checklists de uma vez.

## Mapa lab → artefato

| Lab | Produz | Onde o código mora |
|---|---|---|
| [00-setup](00-setup/) | estação de trabalho pronta | `automation/setup/` |
| [01-packer-primeiro-build](01-packer-primeiro-build/) | imagem base Ubuntu | `packer/templates/ubuntu-base.pkr.hcl` |
| [02-packer-provisioners](02-packer-provisioners/) | imagem Ubuntu + nginx | `packer/templates/ubuntu-nginx.pkr.hcl`<br>`packer/scripts/install-nginx.sh`<br>`packer/files/nginx/default.conf` |
| [03-packer-variaveis](03-packer-variaveis/) | imagem parametrizada | `packer/templates/` + `packer/vars/` |
| [04-packer-multi-source](04-packer-multi-source/) | mesma imagem, 2 bases | `packer/templates/` |
| [05-packer-manifest](05-packer-manifest/) | manifest.json (a ponte) | `packer/templates/` |
| [06-tf-workflow-core](06-tf-workflow-core/) | primeiro container via TF | `terraform/stacks/` |
| [07-tf-variaveis-outputs](07-tf-variaveis-outputs/) | stack parametrizada | `terraform/stacks/` |
| [08-tf-dependencias](08-tf-dependencias/) | rede + volume + grafo | `terraform/stacks/` |
| [09-tf-count-foreach-lifecycle](09-tf-count-foreach-lifecycle/) | N containers | `terraform/stacks/` |
| [10-tf-modulos](10-tf-modulos/) | módulo reutilizável | `terraform/modules/webapp/` |
| [11-tf-state](11-tf-state/) | import, drift, moved | `terraform/stacks/` |
| [12-capstone-ponte](12-capstone-ponte/) | Packer → Terraform | `packer/` + `terraform/stacks/` |
| [13-capstone-ambientes](13-capstone-ambientes/) | dev / prod isolados | `terraform/envs/{dev,prod}/` |
| [14-capstone-empacotar](14-capstone-empacotar/) | pipeline + docs | raiz (`Taskfile.yml`, CI) |
| [15-packer-hyperv-windows](15-packer-hyperv-windows/) | VM Windows Server | `packer/templates/win2022-base.pkr.hcl` |
| [16-ansible-windows-winrm](16-ansible-windows-winrm/) | Windows configurado | `ansible/playbooks/` |
| [17-golden-image-pipeline](17-golden-image-pipeline/) | golden image Windows | `packer/templates/win2022-golden.pkr.hcl` |
| [18-tf-hyperv-provider](18-tf-hyperv-provider/) | VMs a partir da golden | `terraform/stacks/` |
| [19-k8s-cluster-hyperv](19-k8s-cluster-hyperv/) | cluster kubeadm | `ansible/playbooks/` |
| [20-k8s-workload-ingress](20-k8s-workload-ingress/) | workload + ingress | `k8s/manifests/` |
| [21-k8s-vault-postgres](21-k8s-vault-postgres/) | Vault + PostgreSQL | `k8s/helm/` |
| [22-tf-kubernetes-provider](22-tf-kubernetes-provider/) | namespaces via TF | `terraform/stacks/` |

## Blocos

| Bloco | Labs | Tema |
|---|---|---|
| 0 | 00 | Setup da estação |
| 1 | 01–05 | Packer (alvo: Docker) |
| 2 | 06–11 | Terraform (alvo: Docker) |
| 3 | 12–14 | Capstone — Packer → Terraform |
| 4 | 15–18 | Windows Server no Hyper-V |
| 5 | 19–22 | Kubernetes local (mini-KOB) |

## Como trabalhar

1. **O código do lab é o exercício.** Os READMEs trazem o HCL completo como
   gabarito/referência — a disciplina de tentar escrever antes de olhar é sua.
2. **Quebre antes de concluir.** Todo README tem `## Quebre isto`. Um lab só
   está feito depois de provocar o erro, ler a mensagem e entender.
3. **Sempre destrua no fim.** `task clean`, `terraform destroy`. Lixo entre labs
   vira confusão que parece bug da ferramenta e não é.
4. **Anote.** A seção `## Notas` de cada README vira o runbook que você reusa.
5. **Quem roda os comandos é o JZ.** O Claude explica, revisa e interpreta erro
   colado de volta — mas não executa o passo do lab. Exceções: setup de
   tooling, verificações read-only, e validar automação que o próprio Claude
   acabou de escrever.
6. **Primeira vez manual, depois automatiza.** Só faz sentido criar task/script
   para um passo depois de tê-lo feito na mão e entendido.
