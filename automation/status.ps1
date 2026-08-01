#Requires -Version 5.1
<#
Le todos os CHECKLIST.md em docs/labs/ e mostra o progresso por lab.
Read-only: nao altera nenhum arquivo.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
$labsDir = Join-Path $root "docs\labs"

if (-not (Test-Path $labsDir)) {
    Write-Host "docs/labs nao encontrado em $labsDir" -ForegroundColor Red
    exit 1
}

$totalDone = 0
$totalItems = 0

Write-Host ""
Write-Host " LAB                                 PROGRESSO" -ForegroundColor Cyan
Write-Host " ---------------------------------------------------------------" -ForegroundColor DarkGray

Get-ChildItem -Path $labsDir -Directory | Sort-Object Name | ForEach-Object {
    $checklist = Join-Path $_.FullName "CHECKLIST.md"
    if (-not (Test-Path $checklist)) { return }

    $lines = Get-Content $checklist
    $done  = @($lines | Where-Object { $_ -match '^\-\s\[x\]' }).Count
    $open  = @($lines | Where-Object { $_ -match '^\-\s\[\s\]' }).Count
    $items = $done + $open
    if ($items -eq 0) { return }

    $totalDone  += $done
    $totalItems += $items

    $pct = [int](($done / $items) * 100)
    $barLen = 20
    $filled = [int](($done / $items) * $barLen)
    $bar = ("#" * $filled).PadRight($barLen, ".")

    $color = "Yellow"
    if ($pct -eq 100) { $color = "Green" }
    elseif ($pct -eq 0) { $color = "DarkGray" }

    $name = $_.Name.PadRight(34).Substring(0, 34)
    Write-Host (" {0} [{1}] {2,3}%  ({3}/{4})" -f $name, $bar, $pct, $done, $items) -ForegroundColor $color
}

Write-Host " ---------------------------------------------------------------" -ForegroundColor DarkGray
if ($totalItems -gt 0) {
    $totalPct = [int](($totalDone / $totalItems) * 100)
    Write-Host (" TOTAL: {0}% ({1}/{2} itens)" -f $totalPct, $totalDone, $totalItems) -ForegroundColor Cyan
}
Write-Host ""
