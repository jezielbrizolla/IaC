<#
.SYNOPSIS
    Configura Docker Desktop para iniciar automaticamente no boot/login via Task Scheduler

.DESCRIPTION
    Este script cria uma tarefa no Task Scheduler do Windows para iniciar o Docker Desktop
    automaticamente quando o usuário faz login no sistema. A tarefa verifica se o Docker
    já está rodando antes de tentar iniciar, evitando duplicação.
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "Configurando Docker Desktop para auto-start..." -ForegroundColor Cyan

# Verifica se Docker Desktop está instalado (verifica ambos os locais possíveis)
$dockerPaths = @(
    "$env:LOCALAPPDATA\Docker\Docker Desktop\Docker Desktop.exe",
    "C:\Program Files\Docker\Docker\Docker Desktop.exe"
)

$dockerPath = $null
foreach ($path in $dockerPaths) {
    if (Test-Path $path) {
        $dockerPath = $path
        break
    }
}

if (-not $dockerPath) {
    Write-Host "ERRO: Docker Desktop não encontrado nos locais padrão:" -ForegroundColor Red
    foreach ($path in $dockerPaths) {
        Write-Host "  - $path" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Docker Desktop encontrado em: $dockerPath" -ForegroundColor Green

# Cria o script wrapper que verifica se o Docker está rodando
$scriptPath = "$PSScriptRoot\start-docker-if-needed.ps1"
$scriptContent = @'
# Script wrapper para iniciar Docker Desktop apenas se não estiver rodando
$ErrorActionPreference = "Stop"

# Verifica ambos os locais possíveis do Docker
$dockerPaths = @(
    "$env:LOCALAPPDATA\Docker\Docker Desktop\Docker Desktop.exe",
    "C:\Program Files\Docker\Docker\Docker Desktop.exe"
)

$dockerPath = $null
foreach ($path in $dockerPaths) {
    if (Test-Path $path) {
        $dockerPath = $path
        break
    }
}

if (-not $dockerPath) {
    Write-Output "ERRO: Docker Desktop não encontrado"
    exit 1
}

$logPath = "$env:TEMP\docker-autostart.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

try {
    Write-Log "Verificando se Docker Desktop está rodando..."
    
    # Verifica se o processo do Docker Desktop está rodando
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    
    if ($dockerProcess) {
        Write-Log "Docker Desktop já está rodando (PID: $($dockerProcess.Id)). Nenhuma ação necessária."
        exit 0
    }
    
    # Verifica se o serviço do Docker está rodando
    $dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    if ($dockerService -and $dockerService.Status -eq "Running") {
        Write-Log "Serviço Docker já está rodando. Nenhuma ação necessária."
        exit 0
    }
    
    Write-Log "Docker Desktop não está rodando. Iniciando..."
    
    # Inicia o Docker Desktop
    Start-Process $dockerPath -ArgumentList "--background"
    
    # Aguarda um pouco para verificar se iniciou corretamente
    Start-Sleep -Seconds 5
    
    $dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
    if ($dockerProcess) {
        Write-Log "Docker Desktop iniciado com sucesso (PID: $($dockerProcess.Id))."
    } else {
        Write-Log "AVISO: Docker Desktop foi iniciado mas o processo não foi detectado após 5 segundos."
    }
    
} catch {
    Write-Log "ERRO: $_"
    exit 1
}
'@

$scriptContent | Out-File -FilePath $scriptPath -Encoding UTF8
Write-Host "Script wrapper criado em: $scriptPath" -ForegroundColor Green

# Remove tarefa existente se houver
$taskName = "Docker Desktop Auto-Start"
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Tarefa existente removida (se existia)" -ForegroundColor Yellow
} catch {
    # Ignora se não existir
}

# Cria a ação para executar o script wrapper
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" `
    -WorkingDirectory $PSScriptRoot

# Configura o trigger para executar no login do usuário
$trigger = New-ScheduledTaskTrigger `
    -AtLogOn `
    -User $env:USERNAME

# Configura as configurações da tarefa
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -DisallowHardTerminate `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

# Define o principal (usuário atual)
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Highest

# Registra a tarefa
Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Inicia o Docker Desktop automaticamente no login do usuário, verificando se já está rodando" `
    | Out-Null

Write-Host "Tarefa '$taskName' criada com sucesso!" -ForegroundColor Green
Write-Host "O Docker Desktop será iniciado automaticamente no próximo login." -ForegroundColor Cyan
Write-Host "A tarefa verificará se o Docker já está rodando antes de iniciar." -ForegroundColor Cyan

Write-Host "`nConfiguração concluída!" -ForegroundColor Green
Write-Host "Logs serão salvos em: %TEMP%\docker-autostart.log" -ForegroundColor Cyan
