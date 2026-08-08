# Setup — Bloco 4 e 5 (Windows Server no Hyper-V + Kubernetes local)

Pré-requisitos adicionais para os labs 15–22. Faça isto **antes** do lab 15;
os labs 00–14 (Docker) não precisam de nada disto.

## Bloco 4 — Windows Server (Hyper-V)

1. **Habilitar o Hyper-V** (PowerShell como Administrador, reinicia o PC):
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
   Confirme depois do reboot: `Get-VMSwitch` não deve dar erro (mesmo sem
   nenhum switch ainda).

2. **Criar um Virtual Switch externo** — é o que dá IP às VMs na sua rede local:
   ```powershell
   Get-NetAdapter                          # veja o nome do seu adaptador de rede
   New-VMSwitch -Name "LabSwitch" -NetAdapterName "Ethernet" -AllowManagementOS $true
   ```
   Troque `"Ethernet"` pelo nome real do seu adaptador (Wi-Fi também funciona,
   mas cabo é mais estável para os labs).

3. **Baixar as ISOs**:
   - Windows Server: Evaluation gratuita (180 dias) em
     <https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022>,
     **ou** mídia de Volume License se você tiver acesso (ex: benefício
     Visual Studio subscription) — os labs não exigem uma edição específica,
     só ajustar `iso_path` e, se a mídia pedir chave durante o setup,
     adicionar `<ProductKey>` no `Autounattend.xml` (mídia VL normalmente
     **não** pede, já vem com a KMS client setup key).
   - Ubuntu Server 24.04 LTS: <https://ubuntu.com/download/server> — só
     necessária a partir do Lab 19 (Bloco 5), pode baixar mais pra frente.
   - Salve em `labs\ISOs\` (dentro do repo, mas **ignorado pelo git** —
     `.gitignore` já tem `ISOs/` e `*.iso`, não precisa se preocupar em
     versionar sem querer).

4. **Ansible no WSL** (o Ansible controla Windows via WinRM, mas o Ansible em
   si roda melhor em Linux — por isso via WSL, não PowerShell):
   ```bash
   # dentro do WSL Ubuntu
   sudo apt update && sudo apt install -y python3-pip
   pip install ansible pywinrm
   ansible --version
   ```

## Bloco 5 — Kubernetes local (mini-KOB)

Nada de novo software no host além do que o Bloco 4 já trouxe — as VMs do
cluster rodam Ubuntu Server e instalam `kubeadm`/`kubelet`/`kubectl`/`containerd`
sozinhas (comandos no lab 19).

1. **Helm no host Windows** (para os labs 21 e para consultar releases):
   ```powershell
   winget install Helm.Helm
   helm version
   ```

2. **kubectl no host Windows** — normalmente já vem com o Docker Desktop
   (`docker` que você instalou no `00-setup` principal). Confirme:
   ```powershell
   kubectl version --client
   ```
   Se não existir: `winget install Kubernetes.kubectl`.

3. **kubeconfig do cluster no host** — depois do lab 19, copie
   `~/.kube/config` da VM control-plane para `$HOME\.kube\config` no Windows
   (comando exato está no README do lab 19).

## Critério de conclusão deste setup
```powershell
Get-VMSwitch                     # mostra "LabSwitch"
Get-ChildItem labs\ISOs\*.iso    # sua(s) ISO(s) do Windows Server aparecem
helm version
kubectl version --client
```
No WSL: `ansible --version` e `python3 -c "import winrm"` sem erro.

## Recursos de memória
Os labs do Bloco 5 sobem 2 VMs de 4GB cada (control-plane + worker) — reserve
pelo menos 12GB de RAM livre no host antes de começar o lab 19. Se a máquina
tiver menos que isso, reduza `MemoryStartupBytes` para 3GB por VM (o cluster
ainda sobe, só fica mais lento).
