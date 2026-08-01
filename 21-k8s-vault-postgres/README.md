# Kubernetes Lab 3 — Vault + PostgreSQL no cluster

**~2h · essencial · replica a stack do KOB**

## Objetivo
Subir HashiCorp Vault e PostgreSQL no cluster local — a mesma stack que
você gerencia no KOB. Vault injeta segredos no pod do app sem hardcode.

## Pré-requisitos
- Cluster do lab 19 rodando
- Helm instalado (`winget install Helm.Helm`)

## Instalar Vault via Helm
```powershell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

kubectl create namespace vault
helm install vault hashicorp/vault -n vault --set "server.dev.enabled=true" --set "injector.enabled=true"

# Esperar o pod ficar Ready
kubectl -n vault wait --for=condition=Ready pod/vault-0 --timeout=120s
kubectl -n vault get pods
```

## Instalar PostgreSQL via Helm
```powershell
helm repo add bitnami https://charts.bitnami.com/bitnami
kubectl create namespace database

helm install postgres bitnami/postgresql -n database `
  --set auth.postgresPassword=lab21pass `
  --set auth.database=lab21db `
  --set primary.persistence.size=1Gi

kubectl -n database wait --for=condition=Ready pod/postgres-postgresql-0 --timeout=120s
```
> Nota: a continuação de linha do PowerShell é o crase (`` ` ``), não a barra
> invertida (`\`) do bash/WSL. Se você rodar este bloco de dentro do WSL
> (bash), troque os `` ` `` por `\` no fim de cada linha.

## Configurar Vault com segredo do Postgres
```powershell
# Exec no pod do Vault
kubectl -n vault exec -it vault-0 -- /bin/sh

# Dentro do Vault:
vault kv put secret/lab21/db \
  username="postgres" \
  password="lab21pass" \
  host="postgres-postgresql.database.svc.cluster.local" \
  port="5432" \
  database="lab21db"

vault kv get secret/lab21/db

# Configurar Kubernetes auth
vault auth enable kubernetes
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443"

vault policy write lab21-app - <<POLICY
path "secret/data/lab21/db" {
  capabilities = ["read"]
}
POLICY

vault write auth/kubernetes/role/lab21-app \
  bound_service_account_names=lab21-sa \
  bound_service_account_namespaces=lab21-app \
  policies=lab21-app \
  ttl=1h

exit
```

## Deploy do app que consome o segredo
`app-with-vault.yml`:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: lab21-sa
  namespace: lab21-app
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: lab21-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: lab21-app
  template:
    metadata:
      labels:
        app: lab21-app
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "lab21-app"
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/lab21/db"
        vault.hashicorp.com/agent-inject-template-db: |
          {{- with secret "secret/data/lab21/db" -}}
          PGHOST={{ .Data.data.host }}
          PGPORT={{ .Data.data.port }}
          PGDATABASE={{ .Data.data.database }}
          PGUSER={{ .Data.data.username }}
          PGPASSWORD={{ .Data.data.password }}
          {{- end }}
    spec:
      serviceAccountName: lab21-sa
      containers:
        - name: app
          image: postgres:16-alpine
          command: ["sh", "-c", "while true; do sleep 5; source /vault/secrets/db; psql -c 'SELECT version();' && echo 'DB OK'; done"]
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
```

```powershell
kubectl create namespace lab21-app   # se não existir
kubectl apply -f app-with-vault.yml
kubectl -n lab21-app logs -f deployment/app
```

## O passo que mais rende
```powershell
# Ver o segredo injetado pelo Vault Agent (sidecar)
kubectl -n lab21-app exec -it deployment/app -c app -- cat /vault/secrets/db
```
O arquivo contém as credenciais do Postgres — mas elas **não estão** no
YAML de deployment, nem em ConfigMap, nem em Secret do Kubernetes. Vieram
do Vault via sidecar. Esse é o padrão que você já usa no KOB.

## Quebre isto
1. **Mude a policy do Vault para negar acesso** (`capabilities = ["deny"]`).
   O pod reinicia em loop porque o Vault Agent não consegue ler o segredo.
2. **Use o ServiceAccount errado** (troque `lab21-sa` por `default`).
   O Vault rejeita a autenticação — o role só aceita `lab21-sa`.
3. **Apague o segredo do Vault** (`vault kv delete secret/lab21/db`).
   O sidecar falha no próximo refresh. É o cenário "alguém deletou o
   segredo em prod" — o pod para de funcionar.

## Critério de conclusão
O pod do app mostra "DB OK" nos logs, `cat /vault/secrets/db` mostra
as credenciais injetadas, e o PostgreSQL responde com a versão.

## Notas
