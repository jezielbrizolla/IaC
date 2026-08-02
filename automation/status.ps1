#Requires -Version 5.1
<#
Le TODO.md e mostra o progresso por lab (secoes "### NN-nome").
Read-only: nao altera nenhum arquivo.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
$todoPath = Join-Path $root "TODO.md"

if (-not (Test-Path $todoPath)) {
    Write-Host "TODO.md nao encontrado em $todoPath" -ForegroundColor Red
    exit 1
}

$totalDone = 0
$totalItems = 0

Write-Host ""
Write-Host " LAB                                 PROGRESSO" -ForegroundColor Cyan
Write-Host " ---------------------------------------------------------------" -ForegroundColor DarkGray

$lines = Get-Content -Path $todoPath -Encoding UTF8
$currentLab = $null
$done = 0
$items = 0

function Write-LabRow {
    param([string]$Name, [int]$Done, [int]$Items)

    if ($Items -eq 0) { return }
    $script:totalDone += $Done
    $script:totalItems += $Items

    $pct = [int](($Done / $Items) * 100)
    $barLen = 20
    $filled = [int](($Done / $Items) * $barLen)
    $bar = ("#" * $filled).PadRight($barLen, ".")

    $color = "Yellow"
    if ($pct -eq 100) { $color = "Green" }
    elseif ($pct -eq 0) { $color = "DarkGray" }

    $label = $Name.PadRight(34)
    if ($label.Length -gt 34) { $label = $label.Substring(0, 34) }
    Write-Host (" {0} [{1}] {2,3}%  ({3}/{4})" -f $label, $bar, $pct, $Done, $Items) -ForegroundColor $color
}

foreach ($line in $lines) {
    # So conta como lab um header no formato "### NN-nome" (dois digitos +
    # hifen). Subtitulos do indice de conceitos ("### Packer") tambem sao h3
    # mas nao sao labs - sem esse filtro eles apareceriam como secoes vazias.
    if ($line -match '^###\s+(\d{2}-\S+)\s*$') {
        # fecha o lab anterior antes de abrir o novo
        if ($currentLab) { Write-LabRow -Name $currentLab -Done $done -Items $items }
        $currentLab = $Matches[1].Trim()
        $done = 0
        $items = 0
        continue
    }
    if ($line -match '^##\s') {
        # saiu de qualquer secao de lab (ex: entrou noutro Bloco sem ### ainda)
        if ($currentLab) { Write-LabRow -Name $currentLab -Done $done -Items $items }
        $currentLab = $null
        continue
    }
    if ($currentLab -and $line -match '^\-\s\[x\]') { $items++; $done++ }
    elseif ($currentLab -and $line -match '^\-\s\[\s\]') { $items++ }
}
if ($currentLab) { Write-LabRow -Name $currentLab -Done $done -Items $items }

Write-Host " ---------------------------------------------------------------" -ForegroundColor DarkGray
if ($totalItems -gt 0) {
    $totalPct = [int](($totalDone / $totalItems) * 100)
    Write-Host (" TOTAL: {0}% ({1}/{2} itens)" -f $totalPct, $totalDone, $totalItems) -ForegroundColor Cyan
}
Write-Host ""
