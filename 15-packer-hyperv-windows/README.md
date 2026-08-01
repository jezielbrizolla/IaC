# Packer Lab 6 — Windows Server no Hyper-V

**~2.5h · essencial · requer Hyper-V habilitado**

## Objetivo
Criar uma VM Windows Server 2022 a partir de ISO usando o builder `hyperv-iso` do
Packer. É o mesmo workflow que você executava na Dell para golden images de server —
agora com controle total do processo no seu PC.

## Pré-requisitos
- Hyper-V habilitado e funcionando (`Get-VMSwitch` retorna ao menos um switch)
- Virtual Switch externo criado (ver `00-setup/SETUP-HYPERV.md`)
- ISO do Windows Server 2022 Evaluation baixada
  (`SERVER_ISO_2022_Eval.iso` — grátis em https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022)
- Arquivo `Autounattend.xml` para instalação desassistida (criamos abaixo)

## Arquivos a criar

`variables.pkrvars.hcl`:
```hcl
iso_path      = "C:\\ISOs\\SERVER_ISO_2022_Eval.iso"
switch_name   = "LabSwitch"
vm_name       = "lab15-win2022"
disk_size_mb  = 40960
memory_mb     = 4096
cpus          = 2
admin_password = "P@cker2026!"
```

`win2022.pkr.hcl`:
```hcl
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
  iso_url           = var.iso_path
  iso_checksum      = "none"
  generation        = 2
  switch_name       = var.switch_name
  vm_name           = var.vm_name
  disk_size         = var.disk_size_mb
  memory            = var.memory_mb
  cpus              = var.cpus
  enable_secure_boot = true
  secure_boot_template = "MicrosoftWindows"

  # WinRM para comunicação — Packer espera isso no Windows
  communicator      = "winrm"
  winrm_username    = "Administrator"
  winrm_password    = var.admin_password
  winrm_timeout     = "30m"

  # Autounattend.xml para instalação sem intervenção
  cd_files          = ["./Autounattend.xml"]

  shutdown_command   = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer shutdown\""
  shutdown_timeout   = "5m"
}

build {
  sources = ["source.hyperv-iso.win2022"]

  # Validação mínima — o provisioner real vem no lab 16 (Ansible)
  provisioner "powershell" {
    inline = [
      "Write-Host '=== Lab 15: Packer + Hyper-V ==='",
      "Get-ComputerInfo | Select-Object WindowsProductName, OsArchitecture",
      "Write-Host '=== Build timestamp:' (Get-Date -Format o) '==='"
    ]
  }
}
```

`Autounattend.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
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
              <Value>2</Value> <!-- Server Standard (Desktop Experience) -->
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
```

## Rodar
```powershell
cd labs\15-packer-hyperv-windows
packer init .
packer validate -var-file="variables.pkrvars.hcl" .
# Build roda em PowerShell como Administrator (Hyper-V exige elevação)
packer build -var-file="variables.pkrvars.hcl" .
```
O build demora ~15–25 minutos (instala Windows do zero). Acompanhe o
progresso no Hyper-V Manager — você vai ver a VM sendo criada, o Windows
instalando, o WinRM conectando, e o provisioner rodando.

## O passo que mais rende
Enquanto o build roda, abra o **Hyper-V Manager** e observe:
1. A VM sendo criada com as specs que você definiu no HCL
2. O Windows instalando sozinho via `Autounattend.xml` (sem clicar em nada)
3. O WinRM sendo habilitado pelos `FirstLogonCommands`
4. O Packer conectando via WinRM e rodando o provisioner PowerShell

Compare isso com como era feito manualmente na Dell. A diferença:
o `Autounattend.xml` + Packer substitui horas de cliques em wizard.

## Quebre isto
1. **Remova o `Autounattend.xml` do `cd_files`** e rode o build:
   ```hcl
   # cd_files = ["./Autounattend.xml"]   ← comente esta linha
   ```
   O Windows vai parar na tela de idioma e esperar input humano. O Packer
   vai expirar o timeout de WinRM e falhar. É exatamente o cenário de
   "build manual" que o unattend resolve.

2. **Troque a senha no Autounattend mas não no variables.pkrvars.hcl** (ou vice-versa):
   O Windows instala com uma senha, o Packer tenta conectar com outra.
   Timeout de WinRM. Lição: a senha precisa ser a mesma nos dois lugares —
   num pipeline real, vem de Vault.

## Critério de conclusão
O build completa sem erro, o provisioner imprime o `WindowsProductName`
("Windows Server 2022 Standard"), e a imagem exportada existe em
`output-win2022/` (ou o path que o Packer definir).

## Notas
