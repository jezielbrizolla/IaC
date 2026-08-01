#Requires -Version 5.1
<#
Automatiza o CICLO deste lab (init -> fmt -> validate -> build -> verifica
imagem -> reproduz o "Quebre isto" -> checklist) depois que voce ja fez o
lab manualmente pelo menos uma vez e entendeu o que cada passo faz.

Isto NAO substitui fazer o lab na mao da primeira vez - existe pra reverificar
rapido depois de editar o .pkr.hcl, ou como regressao do proprio conteudo
do lab.

O teste de "quebra" roda numa COPIA TEMPORARIA do arquivo, com
PACKER_PLUGIN_PATH apontando pra uma pasta vazia isolada - nunca mexe no seu
docker.pkr.hcl real nem no cache de plugins de verdade.

Uso:
  .\run.ps1                    # roda o ciclo completo
  .\run.ps1 -SkipBreakTest      # pula o teste de quebra (mais rapido)
  .\run.ps1 -SkipChecklistUpdate
#>
[CmdletBinding()]
param(
    [switch]$SkipBreakTest,
    [switch]$SkipChecklistUpdate
)

$ErrorActionPreference = "Continue"
$root = $PSScriptRoot
$sharedLib = Join-Path $root "..\_lib"

Import-Module (Join-Path $sharedLib "Logging.psm1") -Force
Import-Module (Join-Path $sharedLib "Checklist.psm1") -Force

$logDir = Join-Path $root "logs"
$logPath = Start-SetupLog -LogDirectory $logDir

Write-Log "==================================================" -Level STEP
Write-Log " Lab 01 - Packer primeiro build - ciclo automatizado" -Level STEP
Write-Log " Log: $logPath" -Level INFO
Write-Log "==================================================" -Level STEP

function Invoke-Step {
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

function Step-Prereqs {
    Write-Log "Passo 1 - Pre-requisitos (packer, docker)" -Level STEP

    if (-not (Get-Command packer -ErrorAction SilentlyContinue)) {
        Write-Log "packer nao encontrado no PATH. Rode 00-setup/setup-automation/setup.ps1 primeiro." -Level FAIL
        return [PSCustomObject]@{ Name = "Prereqs"; Status = "FAIL"; Detail = "packer ausente" }
    }
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Log "docker nao encontrado no PATH." -Level FAIL
        return [PSCustomObject]@{ Name = "Prereqs"; Status = "FAIL"; Detail = "docker ausente" }
    }

    docker version *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Docker CLI presente mas o daemon nao respondeu. Abra o Docker Desktop." -Level FAIL
        return [PSCustomObject]@{ Name = "Prereqs"; Status = "FAIL"; Detail = "daemon nao respondeu" }
    }

    Write-Log "packer e docker disponiveis, daemon respondendo." -Level OK
    return [PSCustomObject]@{ Name = "Prereqs"; Status = "OK"; Detail = "OK" }
}

function Step-File {
    Write-Log "Passo 2 - Conferindo docker.pkr.hcl" -Level STEP
    $file = Join-Path $root "docker.pkr.hcl"

    if (-not (Test-Path $file)) {
        Write-Log "docker.pkr.hcl nao existe. Escreva o arquivo primeiro (ver README.md)." -Level FAIL
        return [PSCustomObject]@{ Name = "File"; Status = "FAIL"; Detail = "arquivo ausente" }
    }

    $content = Get-Content -Path $file -Raw
    $hasPacker = $content -match '(?s)packer\s*\{.*required_plugins'
    $hasSource = $content -match 'source\s+"docker"\s+"ubuntu"'
    $hasBuild  = $content -match 'build\s*\{'

    if ($hasPacker -and $hasSource -and $hasBuild) {
        Write-Log "docker.pkr.hcl tem os 3 blocos esperados (packer/required_plugins, source, build)." -Level OK
        return [PSCustomObject]@{ Name = "File"; Status = "OK"; Detail = "3 blocos presentes" }
    }

    Write-Log "docker.pkr.hcl esta incompleto ou com o bloco packer{} comentado (esperado so durante o Quebre isto)." -Level WARN
    return [PSCustomObject]@{ Name = "File"; Status = "WARN"; Detail = "algum bloco ausente/comentado" }
}

function Step-Init {
    Write-Log "Passo 3 - packer init" -Level STEP
    Push-Location $root
    try {
        $out = & packer init . 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            $msg = if ($out.Trim()) { $out.Trim() } else { "plugin ja estava instalado" }
            Write-Log "packer init OK: $msg" -Level OK
            return [PSCustomObject]@{ Name = "Init"; Status = "OK"; Detail = $msg }
        }
        Write-Log "packer init falhou: $out" -Level FAIL
        return [PSCustomObject]@{ Name = "Init"; Status = "FAIL"; Detail = $out.Trim() }
    }
    finally { Pop-Location }
}

function Step-FmtValidate {
    Write-Log "Passo 4 - packer fmt + validate" -Level STEP
    Push-Location $root
    try {
        & packer fmt . *> $null
        $out = & packer validate . 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Log "packer validate: configuracao valida." -Level OK
            return [PSCustomObject]@{ Name = "Validate"; Status = "OK"; Detail = "valido" }
        }
        Write-Log "packer validate falhou: $out" -Level FAIL
        return [PSCustomObject]@{ Name = "Validate"; Status = "FAIL"; Detail = $out.Trim() }
    }
    finally { Pop-Location }
}

function Step-Build {
    Write-Log "Passo 5 - packer build" -Level STEP
    Push-Location $root
    try {
        $out = & packer build . 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Write-Log "packer build falhou: $out" -Level FAIL
            return [PSCustomObject]@{ Name = "Build"; Status = "FAIL"; Detail = "build falhou" }
        }

        if ($out -match 'Imported Docker image:\s*sha256:([0-9a-f]+)') {
            $imageId = $Matches[1]
            docker image inspect $imageId *> $null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Build OK, imagem confirmada no Docker: $imageId" -Level OK
                return [PSCustomObject]@{ Name = "Build"; Status = "OK"; Detail = "imagem $imageId" }
            }
            Write-Log "Build reportou sucesso mas a imagem $imageId nao foi encontrada no Docker." -Level FAIL
            return [PSCustomObject]@{ Name = "Build"; Status = "FAIL"; Detail = "imagem nao encontrada" }
        }

        Write-Log "Build rodou sem erro mas nao encontrei a linha 'Imported Docker image' no output." -Level WARN
        return [PSCustomObject]@{ Name = "Build"; Status = "WARN"; Detail = "artifact id nao capturado" }
    }
    finally { Pop-Location }
}

function Remove-PackerBlock {
    # Remove o bloco `packer { ... }` (com chaves aninhadas) via regex de
    # balanceamento .NET - usado so na copia temporaria do teste de quebra.
    param([string]$Content)

    $pattern = '(?s)packer\s*\{(?:[^{}]|(?<open>\{)|(?<-open>\}))*(?(open)(?!))\}'
    return [regex]::Replace($Content, $pattern, '')
}

function Step-BreakTest {
    Write-Log "Passo 6 - Quebre isto (em copia temporaria, isolado)" -Level STEP

    $file = Join-Path $root "docker.pkr.hcl"
    $original = Get-Content -Path $file -Raw
    $stripped = Remove-PackerBlock -Content $original

    if ($stripped -eq $original) {
        Write-Log "Nao encontrei o bloco packer{} pra remover (talvez ja esteja comentado). Pulando o teste de quebra." -Level WARN
        return [PSCustomObject]@{ Name = "BreakTest"; Status = "WARN"; Detail = "bloco packer{} nao encontrado" }
    }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("packer-lab01-break-" + [guid]::NewGuid().ToString("N"))
    $emptyPluginDir = Join-Path ([System.IO.Path]::GetTempPath()) ("packer-lab01-plugins-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    New-Item -ItemType Directory -Path $emptyPluginDir -Force | Out-Null

    try {
        Set-Content -Path (Join-Path $tempDir "docker.pkr.hcl") -Value $stripped -Encoding UTF8

        Push-Location $tempDir
        try {
            $env:PACKER_PLUGIN_PATH = $emptyPluginDir
            $out = & packer build . 2>&1 | Out-String
            Remove-Item Env:\PACKER_PLUGIN_PATH -ErrorAction SilentlyContinue
        }
        finally { Pop-Location }

        if ($LASTEXITCODE -ne 0 -and $out -match "unknown by Packer") {
            Write-Log "Erro reproduzido como esperado: 'unknown by Packer' (plugin isolado, sem required_plugins)." -Level OK
            return [PSCustomObject]@{ Name = "BreakTest"; Status = "OK"; Detail = "erro reproduzido" }
        }

        Write-Log "O teste de quebra NAO reproduziu o erro esperado. Output: $out" -Level FAIL
        return [PSCustomObject]@{ Name = "BreakTest"; Status = "FAIL"; Detail = "erro nao reproduzido" }
    }
    finally {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
        Remove-Item -Recurse -Force $emptyPluginDir -ErrorAction SilentlyContinue
    }
}

$results = @()
$results += Invoke-Step -Name "Prereqs"  -Block { Step-Prereqs }
$results += Invoke-Step -Name "File"     -Block { Step-File }
$results += Invoke-Step -Name "Init"     -Block { Step-Init }
$results += Invoke-Step -Name "Validate" -Block { Step-FmtValidate }
$results += Invoke-Step -Name "Build"    -Block { Step-Build }
if (-not $SkipBreakTest) {
    $results += Invoke-Step -Name "BreakTest" -Block { Step-BreakTest }
}

Write-Log "==================================================" -Level STEP
Write-Log " Resumo" -Level STEP
Write-Log "==================================================" -Level STEP
foreach ($r in $results) {
    $level = "INFO"
    if ($r.Status -eq "OK")   { $level = "OK" }
    if ($r.Status -eq "WARN") { $level = "WARN" }
    if ($r.Status -eq "FAIL") { $level = "FAIL" }
    Write-Log ("{0,-10} {1,-6} {2}" -f $r.Name, $r.Status, $r.Detail) -Level $level
}

if (-not $SkipChecklistUpdate) {
    $checklistPath = Join-Path $root "CHECKLIST.md"
    $patternMap = @(
        @{ Pattern = "Criar .docker\.pkr\.hcl";        Result = "File" }
        @{ Pattern = "packer init .* rodou sem erro";  Result = "Init" }
        @{ Pattern = "packer fmt .* aplicado";         Result = "Validate" }
        @{ Pattern = "packer validate .* sem erros";   Result = "Validate" }
        @{ Pattern = "packer build .* produziu";       Result = "Build" }
        @{ Pattern = "docker image ls.*dangling";      Result = "Build" }
        @{ Pattern = "Quebrei:";                       Result = "BreakTest" }
    )
    Update-SetupChecklist -ChecklistPath $checklistPath -Results $results -PatternMap $patternMap
}

$failCount = @($results | Where-Object { $_.Status -eq "FAIL" }).Count
$warnCount = @($results | Where-Object { $_.Status -eq "WARN" }).Count

Write-Log "==================================================" -Level STEP
if ($failCount -gt 0) {
    Write-Log "$failCount item(ns) com falha. Log completo: $logPath" -Level FAIL
    exit 1
}
elseif ($warnCount -gt 0) {
    Write-Log "$warnCount item(ns) com aviso. Log: $logPath" -Level WARN
    exit 0
}
else {
    Write-Log "Ciclo do lab 01 OK de ponta a ponta." -Level OK
    exit 0
}
