# Ansible Lab 1 — provisionando Windows Server via WinRM

**~2h · essencial · requer VM do lab 15 rodando**

## Objetivo
Configurar um Windows Server com Ansible usando WinRM (não SSH).
Instalar roles, features, e aplicar hardening básico — o dia a dia de quem
gerencia servidores Windows em escala.

## Pré-requisitos
- VM Windows Server do lab 15 rodando no Hyper-V (ou criar uma nova manualmente)
- IP da VM acessível do host (anotar: `$VM_IP`)
- Ansible instalado no WSL: `pip install ansible pywinrm`
- WinRM habilitado na VM (o Autounattend do lab 15 já fez isso)

## Arquivos a criar

`inventory.yml`:
```yaml
all:
  hosts:
    lab16-win:
      ansible_host: "{{ vm_ip }}"  # passar com -e vm_ip=x.x.x.x
      ansible_user: Administrator
      ansible_password: "P@cker2026!"
      ansible_connection: winrm
      ansible_winrm_transport: basic
      ansible_winrm_server_cert_validation: ignore
      ansible_port: 5985
```

`playbook.yml`:
```yaml
---
- name: Lab 16 — configurar Windows Server
  hosts: lab16-win
  gather_facts: yes
  tasks:

    - name: Mostrar informações do sistema
      ansible.windows.win_shell: |
        Get-ComputerInfo | Select-Object WindowsProductName, OsArchitecture, CsName
      register: sysinfo
    - debug: var=sysinfo.stdout_lines

    # --- Instalar features ---
    - name: Instalar Web-Server (IIS)
      ansible.windows.win_feature:
        name: Web-Server
        state: present
        include_management_tools: yes

    - name: Instalar Telnet-Client (ferramenta de diagnóstico)
      ansible.windows.win_feature:
        name: Telnet-Client
        state: present

    # --- Configuração básica ---
    - name: Definir timezone
      community.windows.win_timezone:
        timezone: "E. South America Standard Time"

    - name: Criar pasta de logs padrão
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

    # --- Hardening básico ---
    - name: Desabilitar SMBv1
      ansible.windows.win_powershell:
        script: |
          Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
      ignore_errors: yes   # pode já estar desabilitado

    - name: Configurar política de senha (mínimo 12 caracteres)
      ansible.windows.win_shell: |
        net accounts /minpwlen:12

    - name: Habilitar firewall (reverter o que o lab 15 desabilitou)
      ansible.windows.win_powershell:
        script: |
          Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
          # Manter WinRM aberto para Ansible continuar funcionando
          New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -Protocol TCP -LocalPort 5985,5986 -Action Allow -ErrorAction SilentlyContinue

    # --- Validação ---
    - name: Verificar IIS rodando
      ansible.windows.win_shell: |
        (Get-Service W3SVC).Status
      register: iis_status
    - debug: msg="IIS status: {{ iis_status.stdout | trim }}"

    - name: Teste final — acessar página padrão do IIS
      ansible.windows.win_uri:
        url: http://localhost
        return_content: yes
      register: iis_page
    - debug: msg="IIS respondeu: {{ iis_page.status_code }}"
```

## Rodar
```bash
# No WSL Ubuntu
cd labs/16-ansible-windows-winrm

# Testar conectividade primeiro
ansible -i inventory.yml lab16-win -m ansible.windows.win_ping -e "vm_ip=192.168.1.XX"

# Rodar o playbook
ansible-playbook -i inventory.yml playbook.yml -e "vm_ip=192.168.1.XX" -v
```

## O passo que mais rende
Depois do playbook rodar, acesse a VM pelo Hyper-V Manager e confirme
visualmente:
```powershell
# Na VM Windows
Get-WindowsFeature Web-Server   # State: Installed
Get-Content C:\Logs\Automation\provisioned.txt
(Get-Service W3SVC).Status      # Running
Get-NetFirewallProfile | Select-Object Name, Enabled
```
Compare o estado da VM **antes** (só Windows base do lab 15) com **depois**.
Tudo que mudou foi declarado no YAML — nada foi clicado manualmente.
É o core do Ansible: estado desejado, idempotente, auditável.

## Quebre isto
1. **Rode o playbook duas vezes seguidas.** Na segunda execução, observe que
   quase tudo retorna `ok` (não `changed`) — o Ansible é idempotente.
   As tasks que usam `win_shell` sempre retornam `changed` porque o Ansible
   não sabe se o comando mudou algo. Lição: prefira módulos declarativos
   (`win_feature`, `win_file`) sobre `win_shell` quando possível.

2. **Troque a senha no inventory para uma errada:**
   ```yaml
   ansible_password: "SenhaErrada"
   ```
   Rode de novo. Erro de autenticação WinRM — a mensagem inclui HTTP 401.
   Num ambiente real, a senha viria de Vault, não do inventory.

3. **Mude `ansible_port` para 5986 (HTTPS) sem configurar certificado:**
   Falha de SSL. O WinRM sobre HTTPS exige certificado configurado na VM.
   No lab estamos usando 5985 (HTTP) — em prod, sempre HTTPS.

## Critério de conclusão
O playbook roda sem erros, IIS está `Running`, o arquivo
`C:\Logs\Automation\provisioned.txt` existe com a data do provisionamento,
e o firewall está habilitado com regra de exceção para WinRM.

## Notas
