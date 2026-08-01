# Kubernetes Lab 1 — cluster local no Hyper-V

**~3h · essencial · o mais longo do bloco**

## Objetivo
Subir um cluster Kubernetes com `kubeadm` em VMs Ubuntu no Hyper-V:
1 control-plane + 1 worker. Replica a fundação do KOB no teu PC.

## Pré-requisitos
- ISO do Ubuntu Server 24.04 LTS
- Virtual Switch `LabSwitch` (do lab 15)
- Pelo menos 12GB RAM livres (4GB por VM + host)

## Setup das VMs
Criar 2 VMs Ubuntu no Hyper-V (manual ou via PowerShell):
```powershell
# Control Plane
New-VM -Name "k8s-cp" -MemoryStartupBytes 4GB -NewVHDPath "C:\HyperV\k8s-cp\disk.vhdx" -NewVHDSizeBytes 30GB -Generation 2 -SwitchName "LabSwitch"
Set-VMProcessor -VMName "k8s-cp" -Count 2
Add-VMDvdDrive -VMName "k8s-cp" -Path "C:\ISOs\ubuntu-24.04-live-server-amd64.iso"
Set-VMFirmware -VMName "k8s-cp" -EnableSecureBoot Off   # Ubuntu precisa disso em Gen2

# Worker
New-VM -Name "k8s-w1" -MemoryStartupBytes 4GB -NewVHDPath "C:\HyperV\k8s-w1\disk.vhdx" -NewVHDSizeBytes 30GB -Generation 2 -SwitchName "LabSwitch"
Set-VMProcessor -VMName "k8s-w1" -Count 2
Add-VMDvdDrive -VMName "k8s-w1" -Path "C:\ISOs\ubuntu-24.04-live-server-amd64.iso"
Set-VMFirmware -VMName "k8s-w1" -EnableSecureBoot Off
```
Instalar Ubuntu manualmente (minimal, SSH server habilitado, IPs estáticos).

## Preparar os nós (rodar em AMBAS as VMs via SSH)
```bash
# Desabilitar swap (obrigatório para kubelet)
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Módulos de kernel
cat <<MODEOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
MODEOF
sudo modprobe overlay && sudo modprobe br_netfilter

# Sysctl
cat <<SYSEOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSEOF
sudo sysctl --system

# Containerd
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# kubeadm, kubelet, kubectl
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## Inicializar o cluster (só no control-plane)
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar CNI (Flannel)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

## Juntar o worker
```bash
# No control-plane, gerar o comando de join:
kubeadm token create --print-join-command

# No worker, colar e rodar o comando gerado (com sudo)
sudo kubeadm join <CP_IP>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

## Configurar kubectl no Windows
```powershell
# Copiar kubeconfig da VM para o host
scp user@<CP_IP>:~/.kube/config $HOME\.kube\config
kubectl get nodes   # deve mostrar cp=Ready, w1=Ready
```

## O passo que mais rende
Depois que os dois nós estão `Ready`:
```bash
kubectl get nodes -o wide          # IPs, OS, container runtime
kubectl get pods -A                # todos os pods do sistema
kubectl describe node k8s-cp       # taints, capacity, allocatable
```
Procure o taint `node-role.kubernetes.io/control-plane:NoSchedule` no CP.
É ele que impede workloads de rodar no control-plane — exatamente como
funciona no KOB. Compare com `kubectl describe node k8s-w1` (sem taint).

## Quebre isto
1. **Não desabilite o swap** numa das VMs. O `kubeadm init` ou `join`
   falha com erro explícito sobre swap. É o erro mais comum de setup.
2. **Esqueça o CNI (Flannel).** Os nós ficam `NotReady` indefinidamente.
   O cluster precisa de rede de pods pra funcionar — sem CNI, não há
   comunicação inter-pod.
3. **Rode `kubeadm init` duas vezes** sem `kubeadm reset` antes. Conflito
   de certificados. Sempre `reset` antes de reinicializar.

## Critério de conclusão
`kubectl get nodes` mostra 2 nós `Ready`, pods do `kube-system` todos
`Running`, e `kubectl run test --image=nginx --restart=Never` sobe um
pod no worker.

## Notas
