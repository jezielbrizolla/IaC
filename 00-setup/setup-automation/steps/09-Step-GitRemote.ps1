function Step-GitRemote {
    param(
        [switch]$Push,
        [switch]$Unattended
    )

    Write-Log "Step 9/9 - Remote 'origin' e push" -Level STEP

    $labsRoot = $Global:IaCLabsRoot
    $remoteUrl = "git@github.com:jezielbrizolla/IaC.git"

    Push-Location $labsRoot
    try {
        $existing = git remote get-url origin 2>$null
        if ($LASTEXITCODE -eq 0 -and $existing) {
            Write-Log "Remote 'origin' ja configurado: $existing" -Level OK
        }
        else {
            Write-Log "Remote 'origin' ausente. Adicionando $remoteUrl ..." -Level WARN
            git remote add origin $remoteUrl | Out-Null
            Write-Log "Remote 'origin' adicionado." -Level OK
        }

        $status = git status --porcelain 2>$null
        $hasChanges = -not [string]::IsNullOrWhiteSpace(($status | Out-String))

        git rev-parse --verify HEAD *> $null
        $hasCommits = ($LASTEXITCODE -eq 0)

        if (-not $hasCommits -and -not $hasChanges) {
            Write-Log "Nada para commitar ainda (sem commits, working tree vazio)." -Level WARN
            return [PSCustomObject]@{ Name = "Git Remote"; Status = "WARN"; Detail = "nada a commitar" }
        }

        if ($hasChanges) {
            Write-Log "Ha mudancas nao commitadas. Este script NAO commita sozinho - revise com 'git status' e commite manualmente antes do push." -Level WARN
            return [PSCustomObject]@{ Name = "Git Remote"; Status = "WARN"; Detail = "mudancas pendentes de commit" }
        }

        if (-not $Push) {
            Write-Log "Remote configurado. Push nao solicitado (rode com -Push para habilitar)." -Level OK
            return [PSCustomObject]@{ Name = "Git Remote"; Status = "OK"; Detail = "remote OK, push nao executado" }
        }

        $confirmed = $Unattended
        if (-not $confirmed) {
            $answer = Read-Host "Confirma 'git push -u origin main'? (s/N)"
            $confirmed = ($answer -eq "s")
        }

        if (-not $confirmed) {
            Write-Log "Push cancelado pelo usuario." -Level WARN
            return [PSCustomObject]@{ Name = "Git Remote"; Status = "WARN"; Detail = "push cancelado" }
        }

        Write-Log "Executando 'git push -u origin main'..." -Level WARN
        git push -u origin main
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Push concluido com sucesso." -Level OK
            return [PSCustomObject]@{ Name = "Git Remote"; Status = "OK"; Detail = "push OK" }
        }

        Write-Log "'git push' falhou. Veja a saida acima para o motivo (auth, conflito, etc.)." -Level FAIL
        return [PSCustomObject]@{ Name = "Git Remote"; Status = "FAIL"; Detail = "push falhou" }
    }
    finally {
        Pop-Location
    }
}
