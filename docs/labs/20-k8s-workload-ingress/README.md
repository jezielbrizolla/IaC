# Kubernetes Lab 2 — deploy de workload + Ingress

> **⚠ Conteúdo pendente de migração de estrutura.**
> Este README ainda descreve o layout antigo (uma pasta por lab, com
> `cd` e arquivos soltos). O repo agora usa shape de produção: o código
> deste lab vai morar em `k8s/manifests/`, e os comandos entram por
> `task` a partir da raiz — sem `cd`. O conteúdo conceitual (HCL, o que
> cada bloco faz, o "Quebre isto") segue válido; os **caminhos e comandos**
> serão ajustados quando chegarmos neste lab. Ver [README raiz](../../../README.md).

**~1.5h · essencial**

## Objetivo
Fazer deploy de uma aplicação, expor com Service e Ingress, e configurar
namespace isolation — replica como os namespaces do KOB funcionam.

## Pré-requisitos
- Cluster do lab 19 rodando (2 nós Ready)

## Arquivos a criar

`namespace.yml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: lab20-app
  labels:
    env: dev
    team: sre
```

`deployment.yml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: lab20-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
        - name: nginx
          image: nginx:1.27-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              cpu: 100m
              memory: 128Mi
```

`service.yml`:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: lab20-app
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

`ingress.yml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: lab20-app
spec:
  ingressClassName: nginx
  rules:
    - host: lab20.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-svc
                port:
                  number: 80
```

`networkpolicy.yml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: lab20-app
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web
  namespace: lab20-app
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
    - Ingress
  ingress:
    - ports:
        - port: 80
```

`resourcequota.yml`:
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: lab20-quota
  namespace: lab20-app
spec:
  hard:
    pods: "10"
    requests.cpu: "500m"
    requests.memory: "512Mi"
    limits.cpu: "1"
    limits.memory: "1Gi"
```

## Rodar
```powershell
cd labs\20-k8s-workload-ingress

# Instalar Ingress NGINX controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/baremetal/deploy.yaml

# Aplicar tudo
kubectl apply -f namespace.yml
kubectl apply -f resourcequota.yml
kubectl apply -f deployment.yml
kubectl apply -f service.yml
kubectl apply -f ingress.yml
kubectl apply -f networkpolicy.yml

# Verificar
kubectl -n lab20-app get all
kubectl -n lab20-app describe resourcequota lab20-quota
kubectl -n lab20-app get ingress
kubectl -n lab20-app get networkpolicy
```

## O passo que mais rende
```powershell
# Ver em qual nó cada pod caiu
kubectl -n lab20-app get pods -o wide
# Escalar de 3 para 5
kubectl -n lab20-app scale deployment web --replicas=5
# Ver a quota sendo consumida
kubectl -n lab20-app describe resourcequota lab20-quota
```
Observe `Used` vs `Hard` na quota. Tente escalar para 15 replicas
(acima do limite de 10 pods) — o scheduler recusa.

## Quebre isto
1. **Remova o resource request do deployment** e tente aplicar com a quota
   ativa. Falha: quota exige que todo pod declare requests. É assim que se
   força governança de recursos por namespace.
2. **Aplique a NetworkPolicy e tente `kubectl exec` num pod para acessar
   outro pod por IP.** Timeout — a policy bloqueia. Remova a policy e
   funciona de novo.

## Critério de conclusão
3 pods rodando distribuídos no worker, Service e Ingress configurados,
ResourceQuota ativa mostrando consumo, e NetworkPolicy bloqueando
tráfego não autorizado.

## Notas
