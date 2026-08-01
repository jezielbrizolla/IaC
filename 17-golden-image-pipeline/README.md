# Golden Image Pipeline — Packer + Ansible juntos

**~2h · a ponte do bloco 4**

## Objetivo
Um pipeline de duas etapas: Packer cria a VM, Ansible provisiona tudo,
Packer exporta a golden image final. É o workflow end-to-end que você
levou pra Dell — agora reconstruído do zero.

## Pré-requisitos
- Labs 15 e 16 concluídos
- Ansible rodando no WSL com `pywinrm`

## Arquivos a criar

`golden.pkr.hcl` — igual ao lab 15 mas com provisioner Ansible embutido:
- Source `hyperv-iso` idêntico ao lab 15
- Provisioner `powershell` para config rápida
- Provisioner `ansible` apontando para `playbook-golden.yml` (WinRM)
- Provisioner `powershell` final rodando Sysprep (`/oobe /generalize /shutdown /quiet`)
- Post-processor `manifest` gerando `golden-manifest.json`

`playbook-golden.yml` — o playbook do lab 16 expandido:
- Instalar: Web-Server, NET-Framework-45-Core, Telnet-Client, RSAT-AD-Tools
- Hardening: desabilitar SMBv1, política de senha 12 chars
- Criar estrutura padrão: `C:\Dell\{Logs,Scripts,Config}`
- Tag da golden image em `C:\Dell\Config\golden-image-tag.txt`
- Habilitar RDP
- Windows Update (CriticalUpdates + SecurityUpdates com reboot)

Reutilize o `Autounattend.xml` do lab 15.

## Rodar
```powershell
cd labs\17-golden-image-pipeline
Copy-Item ..\15-packer-hyperv-windows\Autounattend.xml .
packer init .
packer build -var "iso_path=C:\ISOs\SERVER_ISO_2022_Eval.iso" `
             -var "switch_name=LabSwitch" `
             -var "admin_password=P@cker2026!" .
```
Tempo: ~30–45min (instalação + Ansible + Windows Update + Sysprep).

## O passo que mais rende
Abra `golden-manifest.json` e leia. O manifest registra qual imagem foi
produzida, quando, com qual builder. Num pipeline CI/CD, esse JSON alimenta
o próximo estágio (Terraform consumindo a imagem). Compare com o lab 05.

## Quebre isto
1. **Remova o Sysprep.** A imagem funciona, mas VMs criadas a partir dela
   terão o mesmo SID — problema sério em domínio. Sysprep generaliza.
2. **Reduza `winrm_timeout` para 5m** e force um Windows Update pesado.
   O reboot do update pode exceder o timeout e quebrar a conexão.

## Critério de conclusão
`golden-manifest.json` existe, `output-golden/` contém o VHDX, e a VM
desligou sozinha após o Sysprep (sem prompt OOBE).

## Notas
