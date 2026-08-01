#Requires -Version 5.1
<#
Demonstra as 4 formas de passar variavel pro Packer (default, -var,
-var-file, PKR_VAR_*) rodando um build de cada, em sequencia, e mostrando
o resultado final. E o Lab 03 automatizado depois de ja feito na mao -
serve pra reverificar rapido ou repetir a demonstracao sem digitar os
quatro comandos de novo.

Uso:
  .\automation\demo-variable-precedence.ps1
  .\automation\demo-variable-precedence.ps1 -Image app-versioned -VarName app_version
#>
[CmdletBinding()]
param(
    [string]$Image        = "app-versioned",
    [string]$VarName      = "app_version",
    [string]$VarValue     = "2.0",
    [string]$VarFile      = "vars/app-versioned.pkrvars.hcl",
    [string]$EnvValue     = "3.0",
    [string]$Repository   = "meuapp"
)

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot "_lib\Logging.psm1") -Force

$logPath = Start-SetupLog -LogDirectory (Join-Path $PSScriptRoot "logs")
Write-Log "==================================================" -Level STEP
Write-Log " Demo de precedencia de variaveis - $Image (var: $VarName)" -Level STEP
Write-Log " Log: $logPath" -Level INFO
Write-Log "==================================================" -Level STEP

function Invoke-DemoBuild {
    param(
        [Parameter(Mandatory)][string]$Label,
        # [string[]] obrigatorio recusa array vazio por padrao (@()) - o build
        # "default" chama esta funcao sem nenhum arg extra, entao precisa
        # aceitar coleção vazia explicitamente.
        [AllowEmptyCollection()][string[]]$PackerArgs = @()
    )
    Write-Log "$Label" -Level STEP
    $out = & packer build @PackerArgs "templates/$Image.pkr.hcl" 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0) {
        Write-Log "  OK" -Level OK
        return $true
    }
    Write-Log "  FALHOU: $($out.Trim())" -Level FAIL
    return $false
}

Push-Location (Join-Path $root "packer")
$results = @()
try {
    Write-Log "packer init" -Level STEP
    packer init "templates/$Image.pkr.hcl" *> $null

    $results += [PSCustomObject]@{ Forma = "default";    OK = (Invoke-DemoBuild -Label "1/4 - default (sem -var)" -PackerArgs @()) }
    $results += [PSCustomObject]@{ Forma = "-var";       OK = (Invoke-DemoBuild -Label "2/4 - -var `"$VarName=$VarValue`"" -PackerArgs @("-var", "$VarName=$VarValue")) }

    if (Test-Path $VarFile) {
        $results += [PSCustomObject]@{ Forma = "-var-file"; OK = (Invoke-DemoBuild -Label "3/4 - -var-file=$VarFile" -PackerArgs @("-var-file=$VarFile")) }
    }
    else {
        Write-Log "3/4 - $VarFile nao encontrado, pulando -var-file" -Level WARN
        $results += [PSCustomObject]@{ Forma = "-var-file"; OK = $false }
    }

    Write-Log "4/4 - variavel de ambiente PKR_VAR_$VarName=$EnvValue" -Level STEP
    $envKey = "PKR_VAR_$VarName"
    [System.Environment]::SetEnvironmentVariable($envKey, $EnvValue, "Process")
    $envOk = Invoke-DemoBuild -Label "  (build com env var setada)" -PackerArgs @()
    [System.Environment]::SetEnvironmentVariable($envKey, $null, "Process")
    $results += [PSCustomObject]@{ Forma = "PKR_VAR_*"; OK = $envOk }
}
finally {
    Pop-Location
}

Write-Log "==================================================" -Level STEP
Write-Log " Resumo" -Level STEP
foreach ($r in $results) {
    $level = if ($r.OK) { "OK" } else { "FAIL" }
    Write-Log ("{0,-12} {1}" -f $r.Forma, $(if ($r.OK) { "OK" } else { "FALHOU" })) -Level $level
}

Write-Log "==================================================" -Level STEP
Write-Log " docker images $Repository" -Level STEP
docker images $Repository

# $results vazio (ex: excecao abortou o script antes de qualquer build)
# conta como falha - nunca reportar sucesso sem ter rodado nada.
if ($results.Count -eq 0) {
    Write-Log "Nenhuma forma foi executada (script abortou antes). Log: $logPath" -Level FAIL
    exit 1
}

$failCount = @($results | Where-Object { -not $_.OK }).Count
if ($failCount -gt 0) {
    Write-Log "$failCount forma(s) falharam. Log: $logPath" -Level FAIL
    exit 1
}
Write-Log "As 4 formas de passar variavel funcionaram." -Level OK
exit 0
