#Requires -Version 5.1
<#
Smoke test de uma imagem gerada pelo Packer: sobe um container, bate via HTTP,
compara o corpo com o esperado e derruba o container no fim (mesmo se falhar).

Enquanto os templates ainda nao aplicam tag (isso entra no lab 04, com o
post-processor "docker-tag"), o script cai no fallback de pegar a imagem
<untagged> mais recente. Depois que a tag existir, ele usa a tag direto.

Uso:
  .\automation\test-image.ps1 -Image ubuntu-nginx
  .\automation\test-image.ps1 -Image ubuntu-nginx -Expect "packer provisioner lab ok"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Image,
    [string]$Expect = "packer provisioner lab ok",
    [int]$Port = 8080
)

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot "_lib\Logging.psm1") -Force

$logPath = Start-SetupLog -LogDirectory (Join-Path $PSScriptRoot "logs")
Write-Log "Smoke test da imagem '$Image' (log: $logPath)" -Level STEP

# --- resolve qual imagem testar -------------------------------------------
$target = $null
docker image inspect $Image *> $null
if ($LASTEXITCODE -eq 0) {
    $target = $Image
    Write-Log "Usando imagem com tag: $Image" -Level OK
}
else {
    $dangling = @(docker images --filter "dangling=true" --format "{{.ID}}")
    if ($dangling.Count -eq 0) {
        Write-Log "Nenhuma imagem com tag '$Image' e nenhuma imagem <untagged>. Rode 'task packer:build IMAGE=$Image' antes." -Level FAIL
        exit 1
    }
    $target = $dangling[0]
    Write-Log "Template ainda nao aplica tag - usando a imagem <untagged> mais recente: $target" -Level WARN
    Write-Log "A partir do lab 04 (post-processor docker-tag) isso vira uma tag de verdade." -Level INFO
}

# --- sobe, testa, derruba --------------------------------------------------
$container = "smoketest-$Image"
docker rm -f $container *> $null

Write-Log "Subindo container '$container' em localhost:$Port" -Level STEP
docker run -d --name $container -p "${Port}:80" $target nginx -g "daemon off;" *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Log "Falha ao subir o container." -Level FAIL
    exit 1
}

$exitCode = 1
try {
    Start-Sleep -Milliseconds 800

    $body = $null
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 10
        # .Content vem como String ou Byte[] dependendo do Content-Type que o
        # servidor devolve - normaliza para string antes de comparar.
        if ($resp.Content -is [byte[]]) {
            $body = [System.Text.Encoding]::UTF8.GetString($resp.Content)
        }
        else {
            $body = [string]$resp.Content
        }
    }
    catch {
        Write-Log "Requisicao HTTP falhou: $($_.Exception.Message)" -Level FAIL
        $exitCode = 1
        return
    }

    if ($body -match [regex]::Escape($Expect)) {
        Write-Log "Resposta bateu com o esperado: '$Expect'" -Level OK
        $exitCode = 0
    }
    else {
        Write-Log "Resposta NAO bateu. Esperado conter '$Expect', veio: '$($body.Trim())'" -Level FAIL
        $exitCode = 1
    }
}
finally {
    docker rm -f $container *> $null
    Write-Log "Container '$container' removido." -Level INFO
}

exit $exitCode
