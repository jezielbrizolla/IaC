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
- ISO do Windows Server 2022 baixada em `labs\ISOs\` — Evaluation gratuita
  (<https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2022>)
  ou mídia de Volume License (ex: benefício Visual Studio subscription).
  É o único pré-requisito que não dá pra automatizar num script: o download
  exige aceitar termos/licença manualmente.

## Teoria

**Golden image — a ideia por trás de tudo.** Em vez de instalar o Windows
numa VM e configurar cada máquina na mão (o jeito manual: instalar, aplicar
patches, instalar agente, configurar firewall, repetir pra cada servidor
novo), você constrói **uma imagem** com tudo isso já pronto, testado, e
reutilizável. Cada VM nova nasce a partir dela — não é configurada depois,
**já nasce configurada**. É o mesmo princípio de imutabilidade que você já
viu nos Labs de Packer com Docker (01-05): a imagem é o artefato versionado;
a VM é só uma instância descartável dela. A diferença aqui é que "imagem" e
"instalar o sistema operacional do zero" são a mesma coisa — não tem
`FROM ubuntu:22.04` pra herdar, o Packer precisa instalar o Windows inteiro
antes de conseguir configurar qualquer coisa.

**Por que a instalação precisa ser desassistida.** O instalador do Windows,
por padrão, é interativo: idioma, partição, EULA, senha — tudo clique
humano. O Packer não tem mão. A solução, que existe desde o Windows Vista
(o "answer file"), é um XML que responde a todas essas perguntas antes de
qualquer uma aparecer — é isso que o `Autounattend.xml` faz. O Windows
Setup procura esse arquivo automaticamente numa mídia removível (o
`cd_files` do Packer simula isso, montando o XML como um CD virtual junto
da ISO de instalação).

**Por que precisa de WinRM.** Depois que o Windows termina de instalar, o
Packer ainda precisa **entrar** na VM pra rodar o provisioner (o
equivalente Windows do que SSH faz nos Labs Linux). WinRM (Windows Remote
Management) é esse canal — mas ele não vem habilitado por padrão numa
instalação nova. Por isso o `Autounattend.xml` tem uma seção
`FirstLogonCommands` que habilita o WinRM automaticamente no primeiro
login: sem isso, o Windows instala perfeitamente, mas o Packer nunca
consegue falar com ele, e o build trava até estourar o timeout.

**Onde isso encaixa no pipeline maior.** O Packer aqui só faz uma coisa:
constrói a imagem e para. Ele não fica rodando, não gerencia a VM depois.
Quem consome essa imagem — cria N VMs a partir dela, decide quantas, onde —
é o Terraform, no Lab 18 (provider Hyper-V). É o mesmo padrão
Packer→manifest→Terraform do capstone (Labs 12-14), só que a "imagem" agora
é um VHDX em vez de uma imagem Docker.

## O que vamos criar

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
# Grava com LF, UTF-8 sem BOM e quebra de linha final — o padrão do repo
# (ver .gitattributes). `Set-Content -Encoding UTF8` no PowerShell 5.1 grava
# UTF-8 *com BOM*, e o BOM faz o `packer fmt -check` do CI falhar.
function Write-RepoFile($Path, $Content) {
  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
  $lf = ($Content -replace "`r`n", "`n") + "`n"
  [System.IO.File]::WriteAllText((Join-Path $PWD $Path), $lf, (New-Object System.Text.UTF8Encoding $false))
}

Write-RepoFile "packer/templates/win2022-base.pkr.hcl" @'
packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = ">= 1.1.0"
    }
  }
}

variable "iso_path" { type = string }
variable "switch_name" { type = string }
variable "vm_name" { type = string }
variable "disk_size_mb" { type = number }
variable "memory_mb" { type = number }
variable "cpus" { type = number }
variable "admin_password" {
  type      = string
  sensitive = true
}

source "hyperv-iso" "win2022" {
  iso_url      = var.iso_path
  iso_checksum = "none"
  generation   = 1
  switch_name  = var.switch_name
  vm_name      = var.vm_name
  disk_size    = var.disk_size_mb
  memory       = var.memory_mb
  cpus         = var.cpus

  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = var.admin_password
  winrm_timeout  = "30m"

  cd_files = ["files/win2022-base/Autounattend.xml"]

  boot_wait    = "0s"
  boot_command = ["<spacebar><wait1><spacebar><wait1><spacebar>"]

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

Write-RepoFile "packer/vars/win2022-base.pkrvars.hcl" @'
iso_path       = "C:/Users/jezie/OneDrive/Documentos/Estudos/IaC/labs/ISOs/en-us_windows_server_2022_updated_dec_2025_x64_dvd_84450f64.iso"
switch_name    = "LabSwitch"
vm_name        = "lab15-win2022"
disk_size_mb   = 40960
memory_mb      = 4096
cpus           = 2
admin_password = "P@cker2026!"
'@

Write-RepoFile "packer/files/win2022-base/Autounattend.xml" @'
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
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Order>1</Order>
              <PartitionID>1</PartitionID>
              <Format>NTFS</Format>
              <Label>Windows</Label>
              <Active>true</Active>
            </ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo>
            <DiskID>0</DiskID>
            <PartitionID>1</PartitionID>
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
        <ProductKey>
          <Key>VDYBN-27WPP-V4HQT-9VMD4-VMK7H</Key>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
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

Se sua ISO estiver em outro nome/caminho, edite `iso_path` em
`packer/vars/win2022-base.pkrvars.hcl` depois de rodar o script — é o valor
que mais costuma variar de máquina pra máquina.

> **Por que barra normal (`/`), não `C:\\ISOs\\...`:** HCL trata
> `\` como início de sequência de escape dentro de string — precisaria
> dobrar (`\\`) pra representar uma barra literal. Barra normal (`/`)
> funciona igual no Windows e evita esse detalhe todo.
>
> **Por que Generation 1, não Generation 2:** mídia de instalação mostra
> "Press any key to boot from CD or DVD..." por uma janela curtíssima — sem
> apertar a tempo, o firmware desiste e tenta o próximo dispositivo (PXE,
> depois disco vazio). Três tentativas de ajustar o `boot_command` em
> Generation 2 falharam (`boot_wait = "5s"` + 1 tecla; `"0s"` + 8 teclas em
> 8s; `"0s"` + 60 teclas em 60s) — a VM sempre foi pro PXE, com a transição
> da tela preta pro PXE levando **menos de 2 segundos** segundo observação
> real. Isso não é problema de *timing* — é limitação estrutural do Gen2:
> o teclado é um dispositivo **sintético**, que só fica pronto pra receber
> tecla depois que um driver carrega, e esse driver não está disponível
> nesse ponto tão inicial do boot (antes até do Windows Setup começar). Não
> tem tecla que chegue a tempo, não importa quantas vezes se repita.
> **Generation 1 usa teclado PS/2 emulado** — funciona desde o instante
> zero, sem esperar driver nenhum, porque é hardware "burro" simulado, não
> um canal que precisa negociar conexão. Troca: perde UEFI/Secure Boot, que
> não importa pro objetivo deste lab (automação do build, não postura de
> segurança de boot). Junto com a troca, o particionamento no
> `Autounattend.xml` também muda: BIOS/MBR usa uma partição `Primary`
> única marcada `Active`, não o trio EFI+MSR+Primary que UEFI/GPT exige.
>
> **Por que tem `<ProductKey>` no `UserData`:** mídia de Volume License
> (como a usada aqui, benefício Visual Studio subscription) para o Setup com
> `Windows cannot read the <ProductKey> setting from the unattend answer
> file` se o answer file não declarar uma chave — diferente da Evaluation,
> que segue sem pedir nada. A chave usada
> (`VDYBN-27WPP-V4HQT-9VMD4-VMK7H`) é a **GVLK pública do Windows Server
> 2022 Standard** (Generic Volume License Key), publicada pela própria
> Microsoft em
> <https://learn.microsoft.com/windows-server/get-started/kms-client-activation-keys>
> — não é a licença real de ninguém, é a chave "genérica" que mídia VL usa
> pra instalar sem prompt, mantendo a ativação de verdade pro KMS host
> depois (o mesmo fluxo instalar-com-GVLK → ativar-via-KMS de produção).
> Se sua ISO for outra edição (ex: Datacenter), troque pela chave
> correspondente na mesma página.

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

O Packer já destrói a VM de build sozinho ao final (é o comportamento
padrão — você nunca fica com a VM de instalação rodando, só a imagem
capturada). Não sobra nada pra remover aí.

O VHDX exportado em `packer/output-win2022/`, por outro lado, **vale a
pena manter** — é a base pra criar a VM do Lab 16 sem reinstalar o Windows
do zero (o Lab 16 já assume isso: "VM Windows Server do lab 15 rodando **ou
criar uma nova manualmente**" — a golden image é justamente o atalho pra
essa segunda opção). Só limpe quando o Lab 16 não precisar mais dela:

```powershell
Remove-Item -Recurse -Force packer/output-win2022 -ErrorAction SilentlyContinue
```

## Notas

- **Build completo em 7min04s**, com sucesso de ponta a ponta na primeira
  vez que todos os problemas abaixo foram resolvidos juntos — WinRM
  conectou, o provisioner imprimiu `WindowsProductName` e o timestamp, e a
  imagem foi exportada (`lab15-win2022.vhdx`, 10.25GB, confirmado por
  tamanho real do arquivo, não só pelo log do Packer).
- **Esse lab levou 4 rodadas de depuração real antes de completar** — cada
  uma um problema genuinamente diferente, não o mesmo erro reaparecendo:
  1. `oscdimg` ausente (dependência do Windows ADK não documentada
     originalmente) — `could not find a supported CD ISO creation command`.
  2. Falta de RAM livre no host (`vmmemWSL` do Docker/WSL2 comendo 2.1GB) —
     `Não é possível alocar 4096 MB de RAM`. Resolvido com `wsl --shutdown`.
  3. **A causa mais interessante:** Generation 2 (UEFI) não conseguia
     entregar tecla a tempo pro prompt "Press any key to boot from CD or
     DVD..." — três tentativas de ajustar `boot_command` (timing e
     repetição) falharam do mesmo jeito, porque não era problema de
     timing — é limitação estrutural: o teclado sintético do Gen2 exige
     driver carregado, que não existe ainda nesse ponto do boot. Resolvido
     trocando pra **Generation 1** (teclado PS/2 emulado, funciona desde o
     instante zero) — troca de abordagem, não ajuste fino.
  4. Mídia Volume License exigindo `<ProductKey>` no answer file
     (`Windows cannot read the <ProductKey> setting`), diferente da
     Evaluation. Resolvido com a GVLK pública do Windows Server 2022
     Standard, confirmada na documentação oficial da Microsoft antes de
     aplicar (não seria certo arriscar mais um build de 7min com uma chave
     chutada de memória).
- **Warning não-fatal na limpeza final, causa raiz confirmada:** o Packer
  avisou que não conseguiu apagar `output-win2022\lab15-win2022\Snapshots`
  por "direitos de acesso insuficientes". `Get-Acl` confirmou: a própria
  exportação do Hyper-V aplica um **Deny explícito** pra "Todos" em
  `DeleteSubdirectoriesAndFiles` nessa pasta (trava de segurança padrão
  contra apagar snapshot sem querer) — Deny explícito vence Allow, mesmo
  com o usuário tendo `FullControl`. A pasta fica vazia e inofensiva; não
  afeta o VHDX exportado. Comportamento esperado do Hyper-V, não bug.
