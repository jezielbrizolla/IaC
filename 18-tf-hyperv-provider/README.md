# Terraform Lab 7 — Hyper-V provider

**~1.5h · fecha o ciclo IaC local**

## Objetivo
Provisionar VMs Windows Server a partir da golden image do lab 17
usando Terraform com o provider Hyper-V. Fecha o ciclo: Packer cria a
imagem, Terraform instancia quantas VMs quiser a partir dela.

## Pré-requisitos
- Golden image VHDX do lab 17 em `output-golden/`
- Provider `taliesins/hyperv` (community — funciona, mas leia as limitações)
- **WinRM habilitado no host Windows** (o provider fala com o Hyper-V *local* via
  WinRM, não via API direta — sem isso o `terraform plan` trava em timeout):
  ```powershell
  # PowerShell como Administrador, no host (não numa VM)
  Enable-PSRemoting -Force
  winrm quickconfig -quiet
  Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
  Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
  ```

## Arquivos a criar

`main.tf`:
```hcl
terraform {
  required_version = ">= 1.5"
  required_providers {
    hyperv = {
      source  = "taliesins/hyperv"
      version = ">= 1.2.0"
    }
  }
}

variable "hyperv_password" {
  type        = string
  sensitive   = true
  description = "Senha do usuário local usado pelo provider para falar com o Hyper-V via WinRM"
}

provider "hyperv" {
  user            = "Administrator"
  password        = var.hyperv_password
  host            = "localhost"
  port            = 5985
  https           = false
  insecure        = true
  use_ntlm        = true
  tls_server_name = ""
  script_path     = "C:/Temp/terraform_%RAND%.cmd"
  timeout         = "30s"
}

variable "golden_vhdx" {
  type        = string
  description = "Caminho do VHDX da golden image"
}

variable "switch_name" {
  type    = string
  default = "LabSwitch"
}

variable "instances" {
  type    = number
  default = 1
}

resource "hyperv_vhd" "disk" {
  count             = var.instances
  path              = "C:\\HyperV\\lab18-vm${count.index}\\disk.vhdx"
  source            = var.golden_vhdx
  vhd_type          = "Dynamic"
}

resource "hyperv_machine_instance" "vm" {
  count               = var.instances
  name                = "lab18-vm${count.index}"
  generation          = 2
  memory_startup_bytes = 4294967296  # 4GB
  processor_count     = 2

  vm_firmware {
    enable_secure_boot = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  hard_disk_drives {
    path                = hyperv_vhd.disk[count.index].path
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
  }

  network_adaptors {
    name        = "LAN"
    switch_name = var.switch_name
  }
}

output "vm_names" {
  value = [for vm in hyperv_machine_instance.vm : vm.name]
}
```

## Rodar
```powershell
cd labs\18-tf-hyperv-provider
$env:TF_VAR_hyperv_password = "SuaSenhaDoAdministratorLocal"
$env:TF_VAR_golden_vhdx     = "C:\path\to\output-golden\disk.vhdx"

terraform init
terraform plan
terraform apply -auto-approve

# Verificar
Get-VM lab18-vm*
```

## O passo que mais rende
Mude `instances = 2` e rode `terraform apply` de novo. Observe o Terraform
criar **só a segunda VM** — a primeira já existe no state. É o mesmo
conceito dos labs Docker, mas agora com VMs reais.

Depois abra `terraform.tfstate` e procure os IDs das VMs — compare com
`Get-VM | Select-Object Id, Name`. O state mapeia IDs do Hyper-V, exatamente
como mapeava IDs de containers Docker no lab 06.

## Quebre isto
1. **Delete uma VM pelo Hyper-V Manager** (não pelo Terraform). Rode
   `terraform plan` — ele quer recriar. É drift, igual ao lab 06 com Docker.
2. **Mude `count` de 2 para 1.** O Terraform quer destruir `vm1` — mas
   e se ela tivesse dados? Lição: `prevent_destroy` no lifecycle.

## Critério de conclusão
`Get-VM lab18-vm*` mostra VM(s) rodando, `terraform state list` mostra
os recursos, e `terraform destroy` limpa tudo.

## Notas
