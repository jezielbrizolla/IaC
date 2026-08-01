# Checklist do 20-k8s-workload-ingress

- [ ] Cluster do lab 19 rodando
- [ ] Instalar Ingress NGINX controller
- [ ] Criar e aplicar: namespace, deployment, service, ingress
- [ ] Criar e aplicar: resourcequota, networkpolicy
- [ ] `kubectl -n lab20-app get all` → pods Running
- [ ] Pods distribuídos no worker (verificar com `-o wide`)
- [ ] ResourceQuota mostra Used vs Hard
- [ ] Scale para 5 → cabe; scale para 15 → recusado pela quota
- [ ] **Quebre:** deployment sem requests + quota ativa → falha
- [ ] **Quebre:** NetworkPolicy bloqueando tráfego inter-pod
- [ ] Limpeza: `kubectl delete namespace lab20-app`

> Atualize os itens com `[x]` quando concluir.
