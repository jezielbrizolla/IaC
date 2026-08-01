# Checklist do 19-k8s-cluster-hyperv

- [ ] ISO Ubuntu Server 24.04 baixada
- [ ] Criar VM `k8s-cp` (control-plane) no Hyper-V
- [ ] Criar VM `k8s-w1` (worker) no Hyper-V
- [ ] Instalar Ubuntu em ambas (SSH habilitado, IPs estáticos)
- [ ] Desabilitar swap em ambas
- [ ] Configurar módulos de kernel e sysctl em ambas
- [ ] Instalar containerd em ambas (SystemdCgroup = true)
- [ ] Instalar kubeadm, kubelet, kubectl em ambas
- [ ] `kubeadm init` no control-plane → cluster inicializado
- [ ] Configurar kubectl no CP (`$HOME/.kube/config`)
- [ ] Instalar Flannel CNI
- [ ] `kubeadm join` no worker → nó juntou ao cluster
- [ ] `kubectl get nodes` → 2 nós Ready
- [ ] Copiar kubeconfig para o host Windows
- [ ] `kubectl get nodes` funciona do Windows
- [ ] **Quebre:** swap ligado → erro no kubeadm
- [ ] **Quebre:** sem CNI → nós NotReady
- [ ] Pod de teste nginx roda no worker

> Atualize os itens com `[x]` quando concluir.
