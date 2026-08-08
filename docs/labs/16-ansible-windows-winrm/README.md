# Ansible Lab 1 — provisionando Windows Server via WinRM

**~2h · essencial · precisa da golden image do Lab 15**

## Objetivo
Configurar um Windows Server com Ansible usando WinRM (não SSH).
Instalar roles, features, e aplicar hardening básico — o dia a dia de quem
gerencia servidores Windows em escala.

## Pré-requisitos

- **VHDX do Lab 15** em `packer/output-win2022/Virtual Hard Disks/`. Se você
  apagou, rode `task packer:build IMAGE=win2022-base -- -var-file="vars/win2022-base.pkrvars.hcl"`
  de novo (~7 min).
- **Ansible + `pywinrm` no WSL** — ver
  [`docs/labs/00-setup/SETUP-HYPERV.md`](../00-setup/SETUP-HYPERV.md), passo 5.
  Confirme com `wsl -e bash -ic "ansible --version"`.
- **~3 GB de RAM livre** para a VM.

## Teoria

**Onde o Ansible entra.** Você já tem duas ferramentas: o Packer constrói a
imagem, o Terraform provisiona a infra. Falta a camada do meio — **configurar
o que está dentro do sistema operacional**, depois que a máquina existe.

| Ferramenta | Camada | Quando roda |
|---|---|---|
| Packer | constrói a imagem | build time, uma vez |
| Terraform | cria a infra (VM, rede, disco) | provisionamento |
| **Ansible** | **configura dentro do SO** | **depois que a máquina existe** |

Há sobreposição de propósito com o Packer — os dois instalam software. A
diferença é *quando*: Packer congela na imagem, Ansible aplica numa máquina
viva. O Lab 17 junta os dois (Ansible rodando **durante** o build do Packer).

**Agentless — e o que isso custa.** O Ansible não instala agente na máquina
alvo. Ele se conecta, executa, e vai embora. Em Linux isso é SSH; em Windows,
**WinRM** (Windows Remote Management), que é HTTP(S) por baixo.

A consequência: o alvo precisa **já estar acessível** antes do Ansible poder
fazer qualquer coisa. É por isso que o `Autounattend.xml` do Lab 15 tinha
aquele `FirstLogonCommands` habilitando WinRM — sem ele, essa VM seria
inalcançável agora.

**O control node não pode ser Windows.** A documentação oficial da Ansible é
explícita: *"Ansible cannot run on Windows as the control node due to API
limitations on the platform."* Não é falta de pacote, é arquitetura. Por isso
o Ansible roda no **WSL** aqui, e o Windows é apenas o **alvo**.

**Idempotência — o conceito central.** Um playbook bem escrito pode rodar
quantas vezes você quiser: na primeira ele muda o que precisa, nas seguintes
não faz nada. Isso é o que permite rodar em cima de uma máquina em qualquer
estado e chegar no estado desejado.

Mas a idempotência **não é automática** — ela depende do módulo:

| Tipo | Exemplo | Idempotente? |
|---|---|---|
| **Declarativo** | `win_feature: name=Web-Server state=present` | ✅ Sim — verifica antes, só age se precisar |
| **Imperativo** | `win_shell: net accounts /minpwlen:12` | ❌ Não — o Ansible não sabe o que o comando fez, e reporta `changed` sempre |

**A regra prática:** prefira módulo declarativo. Use `win_shell`/`win_powershell`
só quando não existir módulo para o que você precisa — e saiba que aquele
passo vai mentir `changed` toda execução.

**Inventário e playbook — a separação que importa.**

- **`inventory.yml`** — *onde* rodar: hosts, credenciais, como conectar.
- **`playbook.yml`** — *o quê* fazer: as tasks, o estado desejado.

Isso permite o mesmo playbook rodar em dev, homolog e prod trocando só o
inventário. É o mesmo princípio do `-var-file` do Packer e do
`terraform.tfvars` — separar a definição dos valores.

> **Sobre a senha no inventário:** neste lab ela está em texto puro, e está
> **errado** de propósito — é laboratório descartável. Em produção viria do
> Ansible Vault ou de um cofre externo (HashiCorp Vault, que aparece no
> Lab 21). O "Quebre isto" nº 2 explora isso.

## O que vamos criar

| Arquivo | Papel |
|---|---|
| `ansible/inventory/lab16.yml` | onde rodar e como conectar |
| `ansible/playbooks/lab16-win.yml` | o que fazer na máquina |

E uma VM Hyper-V criada **a partir de uma cópia** do VHDX do Lab 15 — nunca
do original. Se o playbook estragar alguma coisa, você joga a cópia fora e
recomeça sem rebuildar 7 minutos de Windows.

## Passo 1 — subir a VM a partir da golden image

Rode em **PowerShell como Administrador** (Hyper-V exige elevação), da raiz
`labs/`:

```powershell
$golden = "$PWD\packer\output-win2022\Virtual Hard Disks\lab15-win2022.vhdx"
$copia  = "$PWD\packer\output-win2022\lab16-win.vhdx"

# Cópia de trabalho — o VHDX do Lab 15 nunca é tocado.
Copy-Item $golden $copia

# Gen 1 obrigatoriamente: o VHDX foi construído como Gen1 no Lab 15
# (trocamos de Gen2 por causa do teclado sintético). VM de geração
# diferente não dá boot nesse disco.
New-VM -Name "lab16-win" -MemoryStartupBytes 3GB -VHDPath $copia `
       -Generation 1 -SwitchName "LabSwitch" | Out-Null
Set-VMProcessor -VMName "lab16-win" -Count 2
Start-VM -Name "lab16-win"
```

Espere a VM subir (~1 min) e descubra o IP dela:

```powershell
Get-VMNetworkAdapter -VMName "lab16-win" | Select-Object -ExpandProperty IPAddresses
```

Anote o IPv4 — você vai passar ele pro Ansible. Se vier vazio, a VM ainda
está bootando; espere e repita.

## Passo 2 — criar o inventário e o playbook

Rode da raiz `labs/` (PowerShell normal, não precisa admin):

```powershell
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). YAML com CRLF funciona, mas o repo padroniza LF.
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

Write-RepoFile "ansible/inventory/lab16.yml" @'
all:
  hosts:
    lab16-win:
      ansible_host: "{{ vm_ip }}"
      ansible_user: Administrator
      ansible_password: "P@cker2026!"
      ansible_connection: winrm
      ansible_winrm_transport: basic
      ansible_winrm_server_cert_validation: ignore
      ansible_port: 5985
'@

Write-RepoFile "ansible/playbooks/lab16-win.yml" @'
---
- name: Lab 16 - configurar Windows Server via WinRM
  hosts: lab16-win
  gather_facts: yes
  tasks:

    - name: Mostrar informacoes do sistema
      ansible.windows.win_shell: |
        Get-ComputerInfo | Select-Object WindowsProductName, OsArchitecture, CsName
      register: sysinfo

    - name: Exibir o que veio
      ansible.builtin.debug:
        var: sysinfo.stdout_lines

    # --- Features: modulo declarativo, idempotente ---
    - name: Instalar Web-Server (IIS)
      ansible.windows.win_feature:
        name: Web-Server
        state: present
        include_management_tools: yes

    - name: Instalar Telnet-Client (ferramenta de diagnostico)
      ansible.windows.win_feature:
        name: Telnet-Client
        state: present

    # --- Configuracao basica ---
    - name: Criar pasta de logs padrao
      ansible.windows.win_file:
        path: C:\Logs\Automation
        state: directory

    - name: Criar arquivo de tag (quem provisionou e quando)
      ansible.windows.win_copy:
        content: |
          Provisioned by: Ansible (Lab 16)
          Date: {{ ansible_date_time.iso8601 }}
          Hostname: {{ ansible_hostname }}
        dest: C:\Logs\Automation\provisioned.txt

    # --- Hardening basico ---
    - name: Desabilitar SMBv1
      ansible.windows.win_powershell:
        script: |
          Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
      ignore_errors: yes

    - name: Configurar politica de senha (minimo 12 caracteres)
      ansible.windows.win_shell: net accounts /minpwlen:12

    - name: Habilitar firewall, mantendo WinRM aberto
      ansible.windows.win_powershell:
        script: |
          New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound `
            -Protocol TCP -LocalPort 5985,5986 -Action Allow -ErrorAction SilentlyContinue
          Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

    # --- Validacao ---
    - name: Verificar IIS rodando
      ansible.windows.win_shell: (Get-Service W3SVC).Status
      register: iis_status

    - name: Mostrar status do IIS
      ansible.builtin.debug:
        msg: "IIS status: {{ iis_status.stdout | trim }}"

    - name: Teste final - acessar a pagina padrao do IIS
      ansible.windows.win_uri:
        url: http://localhost
        return_content: yes
      register: iis_page

    - name: Mostrar resposta do IIS
      ansible.builtin.debug:
        msg: "IIS respondeu: {{ iis_page.status_code }}"
'@
```

> **A ordem do firewall importa.** A regra de exceção do WinRM é criada
> **antes** de habilitar o firewall. Invertido, você fecharia o próprio canal
> que o Ansible está usando — e perderia a conexão no meio do playbook.

## Passo 3 — rodar

Substitua `192.168.15.XX` pelo IP que você anotou no Passo 1:

```powershell
# Teste de conectividade primeiro — falha rápido se o WinRM não responder
wsl -e bash -ic "cd /mnt/c/Users/jezie/OneDrive/Documentos/Estudos/IaC/labs && ansible -i ansible/inventory/lab16.yml lab16-win -m ansible.windows.win_ping -e 'vm_ip=192.168.15.XX'"

# O playbook
wsl -e bash -ic "cd /mnt/c/Users/jezie/OneDrive/Documentos/Estudos/IaC/labs && ansible-playbook -i ansible/inventory/lab16.yml ansible/playbooks/lab16-win.yml -e 'vm_ip=192.168.15.XX'"
```

> **Por que `wsl -e bash -ic`:** o `-i` força modo interativo, que carrega o
> `~/.bashrc` e encontra o `ansible` no `PATH` (ele foi instalado em
> `~/.local/bin`). Sem o `-i`, dá `command not found` — está documentado no
> `SETUP-HYPERV.md`.

## Passo 4 — o passo que mais rende

Conecte na VM pelo Hyper-V Manager e confirme **visualmente** o que o playbook
fez:

```powershell
# Dentro da VM
Get-WindowsFeature Web-Server        # State: Installed
Get-Content C:\Logs\Automation\provisioned.txt
(Get-Service W3SVC).Status           # Running
Get-NetFirewallProfile | Select-Object Name, Enabled
```

Compare o estado da VM **antes** (só o Windows base do Lab 15) com **depois**.
Tudo que mudou foi declarado no YAML — nada foi clicado. É o core do Ansible:
estado desejado, auditável, versionado.

## Quebre isto

1. **Rode o playbook duas vezes seguidas.** Na segunda, observe o `PLAY RECAP`:
   as tasks declarativas viram `ok` (não `changed`), mas as de `win_shell`
   continuam `changed` — porque o Ansible não tem como saber se o comando
   mudou algo. É a Teoria acontecendo na sua frente.
2. **Troque a senha no inventário** para uma errada e rode de novo. Erro de
   autenticação WinRM, com HTTP 401. Num ambiente real a senha viria de
   cofre, não do arquivo.
3. **Mude `ansible_port` para 5986** (HTTPS) sem configurar certificado.
   Falha de SSL — o WinRM sobre HTTPS exige certificado na VM. Este lab usa
   5985 (HTTP) porque é rede local descartável; em produção, sempre HTTPS.

Desfaça os três antes de seguir.

## Critério de conclusão
O playbook roda sem erros, IIS está `Running`, o arquivo
`C:\Logs\Automation\provisioned.txt` existe com a data do provisionamento,
e o firewall está habilitado com a regra de exceção para WinRM.

## Limpeza

```powershell
Stop-VM -Name "lab16-win" -Force -ErrorAction SilentlyContinue
Remove-VM -Name "lab16-win" -Force -ErrorAction SilentlyContinue
Remove-Item "packer\output-win2022\lab16-win.vhdx" -ErrorAction SilentlyContinue
```

> O VHDX **original** do Lab 15 fica — o Lab 17 e o Lab 18 ainda vão usá-lo.

## Notas
