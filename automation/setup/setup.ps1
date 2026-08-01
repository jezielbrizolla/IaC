#Requires -Version 5.1
<#
Orquestrador do setup do Bloco 0 (00-setup). Verifica/instala Terraform, Packer
e Docker Desktop, confere WSL2+Ubuntu, a extensao do VS Code, o repositorio git
e a autenticacao SSH com o GitHub - e loga tudo em console + arquivo.

Uso:
  .\setup.ps1                 # roda todos os passos, nunca commita/pusha sozinho
  .\setup.ps1 -Push            # ao final, se working tree limpo, oferece git push
  .\setup.ps1 -Push -Unattended  # push sem perguntar (uso em automacao/CI local)
  .\setup.ps1 -SkipChecklistUpdate  # nao mexe no CHECKLIST.md
#>
[CmdletBinding()]
param(
    [switch]$Unattended,
    [switch]$Push,
    [switch]$SkipChecklistUpdate
)

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
# automation/setup -> automation/_lib (biblioteca compartilhada)
$sharedLib = Join-Path $root "..\_lib"

Import-Module (Join-Path $sharedLib "Logging.psm1") -Force
Import-Module (Join-Path $sharedLib "Checklist.psm1") -Force

$logDir = Join-Path $root "logs"
$logPath = Start-SetupLog -LogDirectory $logDir

# automation/setup -> automation -> raiz do repo
$Global:IaCLabsRoot = (Resolve-Path (Join-Path $root "..\..")).Path

Write-Log "==================================================" -Level STEP
Write-Log " IaC Track 0 - Setup Automation (Bloco 0)" -Level STEP
Write-Log " Labs root: $($Global:IaCLabsRoot)" -Level INFO
Write-Log " Log file : $logPath" -Level INFO
Write-Log "==================================================" -Level STEP

Get-ChildItem -Path (Join-Path $root "steps") -Filter "*.ps1" | Sort-Object Name | ForEach-Object {
    . $_.FullName
}

function Invoke-Step {
    # Isola cada passo: uma excecao inesperada num passo vira FAIL naquele
    # passo, e nao derruba o orquestrador inteiro.
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Block
    )
    try {
        return (& $Block)
    }
    catch {
        Write-Log "Excecao nao tratada no passo '$Name': $($_.Exception.Message)" -Level FAIL
        return [PSCustomObject]@{ Name = $Name; Status = "FAIL"; Detail = $_.Exception.Message }
    }
}

$results = @()
$results += Invoke-Step -Name "Prerequisites"      -Block { Step-Prerequisites }
$results += Invoke-Step -Name "Terraform"          -Block { Step-Terraform }
$results += Invoke-Step -Name "Packer"             -Block { Step-Packer }
$results += Invoke-Step -Name "Docker Desktop"     -Block { Step-DockerDesktop }
$results += Invoke-Step -Name "WSL Ubuntu"         -Block { Step-WSLUbuntu }
$results += Invoke-Step -Name "VS Code Extension"  -Block { Step-VSCodeExtension }
$results += Invoke-Step -Name "Git Repo"           -Block { Step-GitRepo }
$results += Invoke-Step -Name "SSH"                -Block { Step-SSH }
$results += Invoke-Step -Name "Git Remote"         -Block { Step-GitRemote -Push:$Push -Unattended:$Unattended }
$results += Invoke-Step -Name "Task"               -Block { Step-Task }

Write-Log "==================================================" -Level STEP
Write-Log " Resumo" -Level STEP
Write-Log "==================================================" -Level STEP

foreach ($r in $results) {
    $level = "INFO"
    if ($r.Status -eq "OK")   { $level = "OK" }
    if ($r.Status -eq "WARN") { $level = "WARN" }
    if ($r.Status -eq "FAIL") { $level = "FAIL" }
    Write-Log ("{0,-18} {1,-6} {2}" -f $r.Name, $r.Status, $r.Detail) -Level $level
}

if (-not $SkipChecklistUpdate) {
    $checklistPath = Join-Path $root "..\..\docs\labs\00-setup\CHECKLIST.md"
    Update-SetupChecklist -ChecklistPath $checklistPath -Results $results
}

# @(...) forca contexto de array: sem isso, quando Where-Object retorna
# exatamente 1 item, o resultado nao tem propriedade .Count e a comparacao
# "-gt 0" avalia silenciosamente como falsa (bug classico do PowerShell).
$failCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = @($results | Where-Object { $_.Status -eq "WARN" }).Count

Write-Log "==================================================" -Level STEP
if ($failCount -gt 0) {
    Write-Log "$failCount item(ns) com falha. Corrija e rode o script de novo. Log completo: $logPath" -Level FAIL
    exit 1
}
elseif ($warnCount -gt 0) {
    Write-Log "$warnCount item(ns) com aviso - alguma acao manual e necessaria. Log: $logPath" -Level WARN
    exit 0
}
else {
    Write-Log "Setup completo. Todos os itens OK." -Level OK
    exit 0
}
