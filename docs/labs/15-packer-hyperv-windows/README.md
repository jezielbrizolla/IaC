# Packer Lab 6 — Windows Server no Hyper-V

**~2.5h · essencial · requer Hyper-V habilitado**

## Objetivo
Criar uma VM Windows Server 2022 a partir de ISO usando o builder `hyperv-iso`
do Packer. É o mesmo workflow usado na Dell para golden images de server —
agora com controle total do processo no seu PC.

## Pré-requisitos

- Hyper-V habilitado e funcionando (`Get-VMSwitch` retorna ao menos um switch)
- Virtual Switch externo criado (`LabSwitch` — já feito no setup, ver
  [`docs/labs/00-setup/SETUP-HYPERV.md`](../00-setup/SETUP-HYPERV.md))
- ISO do Windows Server 2022 Evaluation baixada em `C:\ISOs\SERVER_ISO_2022_Eval.iso`
  (grátis em <https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022>
  — é o único pré-requisito que não dá pra automatizar num script: o download
  exige aceitar os termos no site da Microsoft)

## O conceito

Três peças, uma vez só:

- **`win2022-base.pkr.hcl`** — o template. O builder `hyperv-iso` faz o Packer
  criar a VM, montar a ISO, instalar o Windows e falar com ele via WinRM
  (o "SSH do Windows") depois que instala.
- **`win2022-base.pkrvars.hcl`** — os valores (caminho da ISO, specs da VM,
  senha). Mesmo padrão de `-var-file` que você já usou nos Labs 03 e 04.
- **`Autounattend.xml`** — o que faz a instalação ser **desassistida**. Sem
  ele, o instalador do Windows para na tela de idioma esperando clique
  humano — e o Packer, que não tem mão pra clicar, estoura o timeout de
  WinRM e falha. O arquivo automatiza: particionamento, aceite de EULA,
  senha de Administrator, e — crucial — habilita o WinRM via
  `FirstLogonCommands`, senão o Packer nunca consegue conversar com a VM
  depois que ela liga.

## Passo 1 — criar os três arquivos

Um script só, cria tudo. Rode da raiz `labs/`:

```powershell
New-Item -ItemType Directory -Path "packer/files/win2022-base" -Force | Out-Null

Set-Content -Path "packer/templates/win2022-base.pkr.hcl" -Encoding UTF8 -Value @'
packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = ">= 1.1.0"
    }
  }
}

variable "iso_path"        { type = string }
variable "switch_name"     { type = string }
variable "vm_name"         { type = string }
variable "disk_size_mb"    { type = number }
variable "memory_mb"       { type = number }
variable "cpus"            { type = number }
variable "admin_password" {
  type      = string
  sensitive = true
}

source "hyperv-iso" "win2022" {
  iso_url             = var.iso_path
  iso_checksum        = "none"
  generation          = 2
  switch_name         = var.switch_name
  vm_name             = var.vm_name
  disk_size           = var.disk_size_mb
  memory              = var.memory_mb
  cpus                = var.cpus
  enable_secure_boot  = true
  secure_boot_template = "MicrosoftWindows"

  communicator    = "winrm"
  winrm_username  = "Administrator"
  winrm_password  = var.admin_password
  winrm_timeout   = "30m"

  cd_files = ["files/win2022-base/Autounattend.xml"]

  shutdown_command = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer shutdown\""
  shutdown_timeout = "5m"
}

build {
  sources = ["source.hyperv-iso.win2022"]

  provisioner "powershell" {
    inline = [
      "Write-Host '=== Lab 15: Packer + Hyper-V ==='",
      "Get-ComputerInfo | Select-Object WindowsProductName, OsArchitecture",
      "Write-Host '=== Build timestamp:' (Get-Date -Format o) '==='"
    ]
  }
}
'@

Set-Content -Path "packer/vars/win2022-base.pkrvars.hcl" -Encoding UTF8 -Value @'
iso_path       = "C:/ISOs/SERVER_ISO_2022_Eval.iso"
switch_name    = "LabSwitch"
vm_name        = "lab15-win2022"
disk_size_mb   = 40960
memory_mb      = 4096
cpus           = 2
admin_password = "P@cker2026!"
'@

Set-Content -Path "packer/files/win2022-base/Autounattend.xml" -Encoding UTF8 -Value @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Type>EFI</Type>
              <Size>512</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Order>2</Order>
              <Type>MSR</Type>
              <Size>128</Size>
            </CreatePartition>
            <CreatePartition wcm:action="add">
              <Order>3</Order>
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <Format>FAT32</Format>
              <Label>System</Label>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>2</Order>
              <PartitionID>2</PartitionID>
            </ModifyPartition>
            <ModifyPartition wcm:action="add">
              <Order>3</Order>
              <PartitionID>3</PartitionID>
              <Format>NTFS</Format>
              <Label>Windows</Label>
            </ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>3</PartitionID>
          </InstallTo>
          <InstallFrom>
            <MetaData wcm:action="add">
              <Key>/IMAGE/INDEX</Key>
              <Value>2</Value>
            </MetaData>
          </InstallFrom>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
      </UserData>
    </component>
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>en-US</InputLocale>
      <SystemLocale>en-US</SystemLocale>
      <UILanguage>en-US</UILanguage>
      <UserLocale>en-US</UserLocale>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <ComputerName>LAB15-WIN</ComputerName>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64"
               publicKeyToken="31bf3856ad364e35" language="neutral"
               versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>P@cker2026!</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <AutoLogon>
        <Enabled>true</Enabled>
        <Username>Administrator</Username>
        <Password><Value>P@cker2026!</Value><PlainText>true</PlainText></Password>
        <LogonCount>3</LogonCount>
      </AutoLogon>
      <FirstLogonCommands>
        <SynchronousCommand wcm:action="add">
          <Order>1</Order>
          <CommandLine>powershell -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"</CommandLine>
          <Description>Disable firewall for Packer WinRM</Description>
        </SynchronousCommand>
        <SynchronousCommand wcm:action="add">
          <Order>2</Order>
          <CommandLine>powershell -Command "Enable-PSRemoting -Force; Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value True; Set-Item WSMan:\localhost\Service\Auth\Basic -Value True"</CommandLine>
          <Description>Enable WinRM for Packer</Description>
        </SynchronousCommand>
      </FirstLogonCommands>
    </component>
  </settings>
</unattend>
'@
```

Se sua ISO estiver em outro caminho, edite `iso_path` em
`packer/vars/win2022-base.pkrvars.hcl` depois de rodar o script — é o único
valor que costuma variar de máquina pra máquina.

> **Por que `C:/ISOs/...` com barra normal, não `C:\\ISOs\\...`:** HCL trata
> `\` como início de sequência de escape dentro de string — precisaria
> dobrar (`\\`) pra representar uma barra literal. Barra normal (`/`)
> funciona igual no Windows e evita esse detalhe todo.

## Passo 2 — rodar o build

**Precisa ser um terminal PowerShell como Administrador** — Hyper-V exige
elevação para criar VM.

```powershell
task packer:validate IMAGE=win2022-base
task packer:build IMAGE=win2022-base -- -var-file="vars/win2022-base.pkrvars.hcl"
```

O build demora **~15–25 minutos** (instala Windows do zero) — é tempo de
parede, não depende de você. Enquanto espera, abra o **Hyper-V Manager** e
observe:

1. A VM sendo criada com as specs do `.pkrvars.hcl`
2. O Windows instalando sozinho via `Autounattend.xml` — sem clicar em nada
3. O WinRM sendo habilitado pelos `FirstLogonCommands`
4. O Packer conectando via WinRM e rodando o provisioner PowerShell

Compare com como era feito manualmente na Dell: o `Autounattend.xml` +
Packer substitui horas de cliques em wizard.

## Quebre isto

1. **Comente o `cd_files`** em `packer/templates/win2022-base.pkr.hcl`:

   ```hcl
   # cd_files = ["files/win2022-base/Autounattend.xml"]
   ```

   O Windows para na tela de idioma esperando input humano. O Packer estoura
   o timeout de WinRM e falha. É exatamente o cenário de "build manual" que
   o unattend resolve — sem ele, não tem como o Packer prosseguir sozinho.

2. **Troque a senha só no `Autounattend.xml`** (ou só no `.pkrvars.hcl`, não
   nos dois): o Windows instala com uma senha, o Packer tenta conectar com
   outra. Timeout de WinRM. Lição: a senha precisa ser a mesma nos dois
   lugares — num pipeline real, os dois leriam do mesmo cofre (Vault), não
   de dois arquivos digitados à mão.

Desfaça as duas antes de seguir.

## Critério de conclusão
O build completa sem erro, o provisioner imprime o `WindowsProductName`
("Windows Server 2022 Standard"), e a imagem exportada existe em
`packer/output-win2022/` (ou o path que o Packer definir).

## Limpeza

```powershell
Get-VM lab15-win2022 -ErrorAction SilentlyContinue | Remove-VM -Force
Remove-Item -Recurse -Force packer/output-win2022 -ErrorAction SilentlyContinue
```

## Notas
