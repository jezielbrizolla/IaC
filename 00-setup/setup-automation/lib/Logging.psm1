$script:LogFile = $null

function Start-SetupLog {
    param(
        [Parameter(Mandatory)][string]$LogDirectory
    )
    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $script:LogFile = Join-Path $LogDirectory "setup-$stamp.log"
    "=== IaC Track 0 - setup automation - $(Get-Date -Format o) ===" | Out-File -FilePath $script:LogFile -Encoding utf8
    return $script:LogFile
}

function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "OK", "WARN", "FAIL", "STEP")][string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "OK"   { Write-Host $line -ForegroundColor Green }
        "WARN" { Write-Host $line -ForegroundColor Yellow }
        "FAIL" { Write-Host $line -ForegroundColor Red }
        "STEP" { Write-Host $line -ForegroundColor Cyan }
        default { Write-Host $line }
    }

    if ($script:LogFile) {
        $line | Out-File -FilePath $script:LogFile -Append -Encoding utf8
    }
}

function Get-SetupLogPath {
    return $script:LogFile
}

Export-ModuleMember -Function Start-SetupLog, Write-Log, Get-SetupLogPath
