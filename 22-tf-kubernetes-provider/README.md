# Terraform Lab 8 — Kubernetes provider

**~1.5h · o fechamento**

## Objetivo
Gerenciar namespaces, deployments, configmaps e secrets do cluster via
Terraform em vez de kubectl. É o passo que conecta IaC com Kubernetes —
e mostra quando faz sentido (e quando não faz) usar Terraform para K8s.

## Pré-requisitos
- Cluster do lab 19 rodando
- kubectl configurado no host Windows

## Arquivos a criar

`main.tf`:
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}

variable "namespaces" {
  type = map(object({
    env  = string
    team = string
  }))
  default = {
    "lab22-dev" = { env = "dev", team = "sre" }
    "lab22-prod" = { env = "prod", team = "sre" }
  }
}

# Namespaces
resource "kubernetes_namespace" "ns" {
  for_each = var.namespaces
  metadata {
    name = each.key
    labels = {
      env  = each.value.env
      team = each.value.team
      managed-by = "terraform"
    }
  }
}

# ResourceQuota por namespace
resource "kubernetes_resource_quota" "quota" {
  for_each = var.namespaces
  metadata {
    name      = "${each.key}-quota"
    namespace = kubernetes_namespace.ns[each.key].metadata[0].name
  }
  spec {
    hard = {
      pods               = each.value.env == "prod" ? "20" : "10"
      "requests.cpu"     = each.value.env == "prod" ? "2" : "500m"
      "requests.memory"  = each.value.env == "prod" ? "2Gi" : "512Mi"
    }
  }
}

# LimitRange (default resources para pods)
resource "kubernetes_limit_range" "lr" {
  for_each = var.namespaces
  metadata {
    name      = "${each.key}-limits"
    namespace = kubernetes_namespace.ns[each.key].metadata[0].name
  }
  spec {
    limit {
      type = "Container"
      default = {
        cpu    = "100m"
        memory = "128Mi"
      }
      default_request = {
        cpu    = "50m"
        memory = "64Mi"
      }
    }
  }
}

# NetworkPolicy — deny all by default em prod
resource "kubernetes_network_policy" "deny_all_prod" {
  metadata {
    name      = "deny-all"
    namespace = kubernetes_namespace.ns["lab22-prod"].metadata[0].name
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

output "namespaces" {
  value = { for k, v in kubernetes_namespace.ns : k => v.metadata[0].labels }
}
```

## Rodar
```powershell
cd labs\22-tf-kubernetes-provider
terraform init
terraform plan
terraform apply -auto-approve

# Verificar
kubectl get namespaces -l managed-by=terraform
kubectl -n lab22-prod describe resourcequota
kubectl -n lab22-prod get networkpolicy
kubectl -n lab22-dev describe limitrange
```

## O passo que mais rende
Adicione um terceiro namespace ao mapa de `namespaces`:
```hcl
"lab22-staging" = { env = "staging", team = "sre" }
```
Rode `terraform plan` — ele cria **só** o namespace novo + quota + limits.
É o padrão de **tenant provisioning via IaC**: cada novo tenant/namespace
é uma entrada no mapa, com governança aplicada automaticamente.

Agora compare com o lab 20: lá você criou tudo com `kubectl apply`.
Ambos funcionam — a diferença é que o Terraform mantém **state** e detecta
drift. Se alguém deletar a NetworkPolicy manualmente, o próximo `plan` recria.

## Quebre isto
1. **Delete o namespace pelo kubectl:** `kubectl delete namespace lab22-dev`.
   Rode `terraform plan` — quer recriar tudo (namespace + quota + limits + netpol).
   É drift detection em ação.
2. **Adicione um recurso manualmente** dentro de `lab22-prod` (ex: um ConfigMap
   via kubectl). O Terraform **não sabe** — ele só gerencia o que está no `.tf`.
   Lição: Terraform para K8s funciona bem para infra base (namespaces, quotas,
   RBAC, policies). Workloads mudam rápido demais — use GitOps (ArgoCD/Flux).

## Critério de conclusão
Namespaces `lab22-dev` e `lab22-prod` existem com labels `managed-by=terraform`,
quotas e limit ranges aplicados, NetworkPolicy deny-all em prod,
e `terraform destroy` limpa tudo.

## Notas
