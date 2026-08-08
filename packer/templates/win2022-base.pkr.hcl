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
  iso_url      = var.iso_path
  iso_checksum = "none"
  generation   = 1
  switch_name  = var.switch_name
  vm_name      = var.vm_name
  disk_size    = var.disk_size_mb
  memory       = var.memory_mb
  cpus         = var.cpus

  communicator    = "winrm"
  winrm_username  = "Administrator"
  winrm_password  = var.admin_password
  winrm_timeout   = "30m"

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
