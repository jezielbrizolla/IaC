# TODO — IaC Track 0 (Blocos 0–5)

> Arquivo único de progresso. Substitui os 23 `CHECKLIST.md` individuais que
> existiam em `docs/labs/*/` (histórico deles preservado no git). Mantenha
> aberto no VS Code; o chat segue este arquivo em vez de espalhar checklist
> pela conversa.
>
> `task setup` atualiza automaticamente a seção **Bloco 0** ao rodar.
> `task status` lê este arquivo e imprime um resumo no terminal.
> O resto é marcado manualmente conforme os labs avançam.

## Agora

**Próximo: Lab 08 — Dependências e o grafo** (Bloco 2, Terraform)
Ainda não iniciado. Stack novo: `terraform/stacks/web-network/`.

## Backlog / Pendências

Itens que foram ficando pra depois durante a sessão, não presos a um lab
específico:

- [ ] Adicionar tasks `tf:init` / `tf:plan` / `tf:apply` / `tf:destroy` ao
      `Taskfile.yml` — regra era "só depois de fazer na mão pelo menos uma
      vez"; já foi feito nos Labs 06/07, pode adicionar agora
- [ ] Decidir Hyper-V local (`hyperv-iso`) vs Azure (`azure-arm`) quando
      chegar no Bloco 4 — créditos Azure disponíveis (US$100)
- [ ] Confirmar se a vaga é híbrida (on-prem + cloud) ou só nuvem pública —
      muda se vale investir em `vsphere`/`dell-redfish`
- [ ] Exercício de consolidação adiado: refazer um lab do zero sem consultar
      (decisão do JZ: mapa completo primeiro, consolidar depois)
- [ ] Drift detection agendado no CI (`terraform plan -detailed-exitcode`) —
      depois de fechar o Bloco 2
- [ ] `tfsec`/`checkov` no CI — depois de fechar o Bloco 2
- [ ] Gaps do "conceito completo" fora do escopo direto da vaga: baremetal→SO
      (Redfish/PXE/MAAS), VMware/vSphere, GitOps (só mencionado no Lab 22)

## Progresso

| Bloco | Labs | Status |
|---|---|---|
| 0 — Setup | 00 | ✅ 19/19 |
| 1 — Packer | 01–05 | ✅ 46/46 |
| 2 — Terraform | 06–11 | 🔶 26/75 |
| 3 — Capstone | 12–14 | ⬜ 0/37 |
| 4 — Windows/Hyper-V | 15–18 | ⬜ 0/45 |
| 5 — Kubernetes | 19–22 | ⬜ 0/54 |
| **Total** | | **91/276 (33%)** |

---

## Bloco 0 — Setup

### 00-setup
- [x] Instalar Terraform (`winget install Hashicorp.Terraform`)
- [x] Instalar Packer (`winget install Hashicorp.Packer`)
- [x] Instalar Docker Desktop com backend WSL2
- [x] Habilitar integração WSL no Docker Desktop
- [x] Instalar extensão HashiCorp Terraform no VS Code
- [x] Inicializar repositório Git na pasta `labs/`
- [x] Configurar chave SSH `ssh-iac` no Ubuntu WSL
- [x] Configurar chave SSH `ssh-iac` no PowerShell/Windows
- [x] Validar `ssh -T git@github.com` no Windows/Git Bash → autenticou como `jezielbrizolla`
- [x] Validar `ssh -T git@github.com` dentro do WSL Ubuntu → autenticou como `jezielbrizolla`
- [x] Criar repositório remoto no GitHub — https://github.com/jezielbrizolla/IaC
- [x] Adicionar `origin` (SSH) apontando para `git@github.com:jezielbrizolla/IaC.git`
- [x] Fazer commit inicial em `labs/`
- [x] Enviar o primeiro push para `origin main`
- [x] Validar `terraform -version` → 1.15.8
- [x] Validar `packer version` → 1.16.0
- [x] Validar `docker run hello-world`
- [x] Instalar go-task (`winget install Task.Task`)
- [x] Validar `task --version` → 3.52.0

## Bloco 1 — Packer

### 01-packer-primeiro-build
Artefato: `packer/templates/ubuntu-base.pkr.hcl`
- [x] Escrever o template com `required_plugins` + `source "docker"` + `build`
- [x] `task packer:init` — plugin baixado
- [x] `packer fmt` aplicado
- [x] `task packer:validate IMAGE=ubuntu-base` sem erros
- [x] `task packer:build IMAGE=ubuntu-base` produziu uma imagem
- [x] `docker image ls --all --filter "dangling=true"` mostra a imagem (`<untagged>` — normal, o Lab 04 fecha isso)
- [x] Quebrei: comentei `required_plugins` + isolei o cache de plugins, li o erro real ("unknown by Packer")
- [x] Sei explicar em 1 frase o que `commit = true` faz
- [x] Notas preenchidas no README

### 02-packer-provisioners
Artefatos: `packer/templates/ubuntu-nginx.pkr.hcl`, `packer/scripts/install-nginx.sh`, `packer/files/nginx/default.conf`
- [x] Escrever a config do nginx
- [x] Escrever o template com `provisioner "shell"` + `provisioner "file"`
- [x] `packer init` / `packer build` OK
- [x] Container rodando e servindo a config própria
- [x] Resposta HTTP retorna o texto de teste
- [x] Container de teste removido
- [x] Migrar `inline` → `script` externo
- [x] Rebuild com script externo funcionou igual
- [x] Quebrei: inverti `file` antes de `shell`, li o erro ("must be a directory"), voltei ao normal
- [x] Notas preenchidas no README

### 03-packer-variaveis
Artefatos: `packer/templates/app-versioned.pkr.hcl`, `packer/vars/app-versioned.pkrvars.hcl`
- [x] Escrever o template com `variable`, `locals`, `post-processor "docker-tag"`
- [x] Escrever `packer/vars/app-versioned.pkrvars.hcl`
- [x] Build com default (`app_version=1.0`)
- [x] Build com `-var "app_version=2.0"`
- [x] Build com `-var-file` (1.1)
- [x] Build com `PKR_VAR_app_version` (3.0)
- [x] `docker images meuapp` mostra as 4 tags
- [x] `packer inspect .` rodado e entendido
- [x] Quebrei: variável obrigatória sem valor → "Unset variable", numa cópia temporária
- [x] Testei `sensitive = true` — não aparece nem no build nem no `inspect` (`<unknown>`)
- [x] Notas preenchidas no README

### 04-packer-multi-source
Artefato: `packer/templates/multi-base.pkr.hcl`
- [x] Escrever o template com dois `source` (ubuntu, alpine)
- [x] Provisioners com `only = [...]` separados por source
- [x] `post-processor "docker-tag"` usando `tags = ["${source.name}"]`
- [x] `task packer:build IMAGE=multi-base` produziu as duas imagens num único comando
- [x] `docker images multi-base` mostra `multi-base:ubuntu` e `multi-base:alpine`
- [x] Quebrei: provisioner `apt-get` sem `only` → Alpine falhou (exit 127)
- [x] Li o erro completo e identifiquei o source que falhou
- [x] Voltei para os provisioners separados
- [x] Notas preenchidas no README

### 05-packer-manifest
Artefato: `packer/templates/golden-manifest.pkr.hcl`
- [x] Adicionar `post-processor "manifest"` ao template
- [x] Build gerou `manifest.json`
- [x] Rodei 2+ builds, `builds[]` acumula entradas
- [x] Identifiquei os campos: `name`, `artifact_id`, `packer_run_uuid`, `last_run_uuid`
- [x] Quebrei: 5 builds seguidos, decidi a regra pra "imagem certa"
- [x] Regra anotada nas Notas (`last_run_uuid == packer_run_uuid`, não posição do array)
- [x] Sei explicar por que este JSON é a ponte pro Terraform

## Bloco 2 — Terraform

### 06-tf-workflow-core
Artefato: `terraform/stacks/web-basic/main.tf`
- [x] Escrever o stack com `terraform{}` + `provider "docker"` + `docker_image` + `docker_container`
- [x] `init` OK — provider `kreuzwerker/docker v3.9.0`, lock file criado
- [x] `fmt` / `validate` limpos
- [x] `plan` revisado antes de aplicar (`2 to add`)
- [x] `apply -auto-approve` OK
- [x] `curl localhost:8080` retorna a página do nginx
- [x] Li o `terraform.tfstate` — `resources`, `attributes`, `serial`, `lineage`
- [x] Comparei o `id` do state com `docker inspect` — idênticos
- [x] Quebrei: apaguei o state com o container no ar, plan quis recriar tudo
- [x] Restaurei o backup — `plan` voltou a `No changes`
- [x] `destroy -auto-approve` deixou `docker ps -a` limpo
- [x] Notas preenchidas no README

### 07-tf-variaveis-outputs
Artefato: `terraform/stacks/web-basic/` (expande o Lab 06)
- [x] Criar `variables.tf` com `container_name`, `external_port` (`validation`), `labels`
- [x] Modificar `main.tf`: `locals.full_name`, `var.external_port`
- [x] Criar `outputs.tf` com `url` e `container_id`
- [x] Criar `terraform.tfvars` com `external_port = 8081`
- [x] Apply com `terraform.tfvars` (8081) — destroy+create pela mudança de nome
- [x] Apply com `-var` (8082) — venceu o tfvars
- [x] Apply com `TF_VAR_external_port` (8083, sem tfvars no caminho) — env var venceu
- [x] `terraform output` mostrando `url` e `container_id`
- [x] Quebrei: `external_port=80`, li a mensagem de validação
- [x] Notei diferença create vs replace na validação
- [x] Reescrevi a `error_message` com minhas palavras
- [x] Sei explicar a diferença entre `variable` e `locals`
- [x] `destroy` no final
- [x] Notas preenchidas no README

### 08-tf-dependencias
Stack sugerido: `terraform/stacks/web-network/`
- [ ] Criar `main.tf` com `docker_network`, `docker_volume`, `docker_container` (referência implícita)
- [ ] `terraform apply` OK
- [ ] `terraform graph > graph.dot` gerado e lido
- [ ] Reescrevi usando `depends_on` explícito e comparei o grafo
- [ ] Voltei para a versão com referência de atributo (a correta)
- [ ] Conclusão implícito vs `depends_on` anotada nas Notas
- [ ] Quebrei: `circular.tf` com dependência circular, li o erro `Cycle: ...`
- [ ] Apaguei `circular.tf` depois do teste
- [ ] Notas preenchidas no README

### 09-tf-count-foreach-lifecycle
- [ ] Criar `main.tf` com a imagem compartilhada
- [ ] Criar `count.tf`, apply com 3 containers
- [ ] Remover item do meio, `plan` (sem aplicar), ler o destroy/recreate indevido
- [ ] `destroy` e trocar para `foreach.tf`
- [ ] Apply com `for_each`, remover item, `plan` confirma que só ele é destruído
- [ ] Diferença count vs for_each anotada nas Notas
- [ ] Testar `create_before_destroy = true`
- [ ] Testar `ignore_changes = [image]`
- [ ] Testar `prevent_destroy = true` e ler o erro (depois remover)
- [ ] `destroy` limpo no final
- [ ] Notas preenchidas no README
- [ ] **Conectar com objetivo:** esse mapa é o padrão de tenant — cada entrada = um tenant

### 10-tf-modulos
- [ ] Criar `modules/webapp/` com `main.tf`, `variables.tf`, `outputs.tf`
- [ ] Criar `main.tf` (root) chamando `module "app_a"` e `module "app_b"`
- [ ] Criar `outputs.tf` (root) expondo outputs dos módulos
- [ ] `terraform init` OK (registrou os módulos)
- [ ] `terraform apply` — duas apps no ar
- [ ] `curl localhost:8091` e `curl localhost:8092` respondem
- [ ] Testei os 3 formatos de `source` (local aplicado, git/registry só lidos)
- [ ] Quebrei: módulo novo sem `init` antes → erro
- [ ] Testei: recurso novo dentro de módulo existente sem `init` → funciona
- [ ] `destroy` limpo
- [ ] Notas preenchidas no README
- [ ] **Conectar com objetivo: este é *o* lab.** Módulo = unidade reutilizável = "o que um tenant precisa"

### 11-tf-state
- [ ] Base aplicada
- [ ] `terraform state list` / `state show` explorados
- [ ] Container órfão criado fora do Terraform
- [ ] `terraform import` rodou
- [ ] Ajustei a config até `plan` ficar vazio
- [ ] Testei bloco `import {}` + `-generate-config-out`
- [ ] Drift: parei o container fora → `plan` detectou
- [ ] Testei `-refresh-only`
- [ ] Renomeei recurso, vi o plan querer destruir/criar
- [ ] Resolvi com `terraform state mv`
- [ ] Resolvi (de novo) com bloco `moved {}`
- [ ] `state rm` — confirmei que o recurso continua vivo
- [ ] Sei explicar `state rm` vs `destroy`
- [ ] Limpeza final
- [ ] Notas preenchidas no README
- [ ] **Conectar com objetivo:** state separado por tenant ou por stack? O que acontece se um corrompe?

## Bloco 3 — Capstone

### 12-capstone-ponte
- [ ] Criar `nginx.conf`, `setup.sh`, template Packer com `post-processor "manifest"`
- [ ] `packer build` gerou `manifest.json`
- [ ] Criar Terraform lendo o manifest via `data "local_file"` + `jsondecode()`
- [ ] `terraform apply` subiu o container com a imagem do Packer
- [ ] `curl` retorna `capstone v1`
- [ ] Editei config, rebuild do Packer, `plan` propôs substituir
- [ ] `apply` e confirmei `capstone v2`
- [ ] Quebrei: apaguei `manifest.json`, li o erro do `data` source
- [ ] Restaurei o manifest
- [ ] `destroy` limpo
- [ ] Notas preenchidas no README

### 13-capstone-ambientes
- [ ] Criar `main.tf` usando `terraform.workspace`
- [ ] Criar `dev.tfvars` e `prod.tfvars`
- [ ] `workspace new dev` / `new prod`
- [ ] Apply em dev com `dev.tfvars`
- [ ] Apply em prod com `prod.tfvars`
- [ ] Confirmei `terraform.tfstate.d/` — um state por workspace
- [ ] Reproduzi a armadilha: `prod` selecionado + `dev.tfvars` aplicado por engano
- [ ] Entendi por que não há barreira estrutural entre workspaces
- [ ] Criei `modules/stack/` + `envs/dev/` + `envs/prod/`
- [ ] Apply funcionando nos dois diretórios separados
- [ ] Conclusão "diretório > workspace" anotada nas Notas
- [ ] Limpeza completa
- [ ] Notas preenchidas no README
- [ ] **Conectar com objetivo:** isolamento por diretório/backend é o padrão que escala pra isolamento por tenant

### 14-capstone-empacotar
- [ ] Criar `build.ps1` (packer → terraform, ponta a ponta)
- [ ] Criar `destroy.ps1`
- [ ] README do capstone: o quê, por quê, como rodar em 3 comandos
- [ ] Diagrama mermaid incluído
- [ ] `.terraform.lock.hcl` confirmado versionado
- [ ] Versões pinadas
- [ ] Seção "próximos passos: AWS"
- [ ] `.\build.ps1` rodou do zero e funcionou
- [ ] `.\destroy.ps1` limpou tudo
- [ ] Pedi pra alguém seguir só o README sem ajuda
- [ ] Commit + push do capstone
- [ ] Notas preenchidas no README

## Bloco 4 — Windows Server (Hyper-V)

> ⚠️ Decisão pendente: Hyper-V local vs Azure Marketplace (`azure-arm`). Ver Backlog.

### 15-packer-hyperv-windows
- [ ] Virtual Switch externo criado (`LabSwitch`) ✅ *já feito, fora de ordem*
- [ ] ISO do Windows Server 2022 Evaluation baixada
- [ ] Criar `variables.pkrvars.hcl`
- [ ] Criar template com builder `hyperv-iso`
- [ ] Criar `Autounattend.xml`
- [ ] `packer init .` → plugins baixados
- [ ] `packer validate -var-file="variables.pkrvars.hcl" .` → sem erros
- [ ] `packer build -var-file="variables.pkrvars.hcl" .` → build inicia
- [ ] Observar no Hyper-V Manager: instalação sozinha
- [ ] WinRM conecta, provisioner roda
- [ ] Build completa → imagem exportada
- [ ] Quebre: remover Autounattend → timeout WinRM
- [ ] Quebre: dessincronizar senha → falha de auth
- [ ] Limpeza

### 16-ansible-windows-winrm
- [ ] Ansible + pywinrm no WSL
- [ ] VM Windows Server rodando (IP anotado)
- [ ] Criar `inventory.yml` com credenciais WinRM
- [ ] Criar `playbook.yml` com tasks de feature, hardening e validação
- [ ] `win_ping` → pong
- [ ] Playbook roda sem erros
- [ ] IIS instalado e rodando
- [ ] `provisioned.txt` existe
- [ ] Firewall habilitado, regra WinRM presente
- [ ] Quebre: idempotência (2ª execução)
- [ ] Quebre: senha errada → HTTP 401
- [ ] Quebre: porta 5986 sem cert → falha SSL

### 17-golden-image-pipeline
- [ ] Copiar `Autounattend.xml` do Lab 15
- [ ] Template com provisioners PowerShell + Ansible + Sysprep
- [ ] `playbook-golden.yml`
- [ ] `packer init .` e `packer build` → build completo
- [ ] Ansible provisiona via WinRM durante o build
- [ ] Sysprep executa, VM desliga sozinha
- [ ] `golden-manifest.json` gerado
- [ ] Quebre: sem Sysprep → SID duplicado
- [ ] Quebre: timeout curto → perda de conexão no reboot

### 18-tf-hyperv-provider
- [ ] Golden image VHDX disponível
- [ ] `main.tf` com provider `taliesins/hyperv`
- [ ] `init` → provider baixado
- [ ] `apply` → VM criada a partir da golden image
- [ ] Verificar VM rodando: `Get-VM lab18-vm*`
- [ ] Escalar pra 2 instâncias → só a segunda é criada
- [ ] Inspecionar state → IDs do Hyper-V mapeados
- [ ] Quebre: deletar VM fora do TF → drift
- [ ] Quebre: reduzir count → destroy vs prevent_destroy
- [ ] `destroy` limpo

## Bloco 5 — Kubernetes (mini-KOB)

### 19-k8s-cluster-hyperv
- [ ] ISO Ubuntu Server 24.04 baixada
- [ ] Criar VM `k8s-cp` (control-plane) no Hyper-V
- [ ] Criar VM `k8s-w1` (worker) no Hyper-V
- [ ] Ubuntu instalado (SSH, IPs estáticos)
- [ ] Swap desabilitado
- [ ] Módulos de kernel e sysctl
- [ ] containerd (SystemdCgroup=true)
- [ ] kubeadm/kubelet/kubectl instalados
- [ ] `kubeadm init` no control-plane
- [ ] kubectl configurado no CP
- [ ] Flannel CNI
- [ ] `kubeadm join` no worker
- [ ] `kubectl get nodes` → 2 Ready
- [ ] Copiar kubeconfig para o host Windows
- [ ] `kubectl get nodes` funciona do Windows
- [ ] Quebre: swap ligado → erro
- [ ] Quebre: sem CNI → NotReady
- [ ] Pod de teste roda no worker

### 20-k8s-workload-ingress
- [ ] Cluster do Lab 19 rodando
- [ ] Ingress NGINX controller
- [ ] namespace, deployment, service, ingress
- [ ] resourcequota, networkpolicy
- [ ] `kubectl -n lab20-app get all` → pods Running
- [ ] Pods distribuídos no worker (verificar com `-o wide`)
- [ ] ResourceQuota Used vs Hard
- [ ] Scale 5 cabe, scale 15 recusado
- [ ] Quebre: sem requests + quota → falha
- [ ] Quebre: NetworkPolicy bloqueando tráfego
- [ ] Limpeza

### 21-k8s-vault-postgres
- [ ] Helm instalado
- [ ] Vault via Helm (dev mode + injector)
- [ ] PostgreSQL via Helm
- [ ] Segredo criado no Vault
- [ ] Kubernetes auth habilitado
- [ ] Policy + role para o ServiceAccount
- [ ] `app-with-vault.yml` com annotations
- [ ] Pod mostra "DB OK"
- [ ] Credenciais injetadas pelo sidecar confirmadas
- [ ] Quebre: policy deny → pod em loop
- [ ] Quebre: ServiceAccount errado → auth falha
- [ ] Quebre: deletar segredo → sidecar falha
- [ ] Limpeza

### 22-tf-kubernetes-provider
- [ ] Cluster rodando, kubectl configurado
- [ ] `main.tf` com provider kubernetes + `for_each`
- [ ] `init` → provider baixado
- [ ] `apply` → namespaces + quotas + policies
- [ ] dev e prod com labels corretos
- [ ] ResourceQuota diferente dev vs prod
- [ ] NetworkPolicy deny-all só em prod
- [ ] Adicionar "staging" ao mapa → `plan` cria só o novo
- [ ] Quebre: deletar namespace via kubectl → drift
- [ ] Quebre: recurso manual → TF não sabe
- [ ] `destroy` limpo
- [ ] **Conectar com objetivo:** provisiona namespace por tenant via mapa, com quota e policy automáticas
