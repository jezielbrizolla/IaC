function Step-GitRepo {
    Write-Log "Step 7/9 - Repositorio Git local (labs/)" -Level STEP

    $labsRoot = $Global:IaCLabsRoot
    $gitDir = Join-Path $labsRoot ".git"

    if (Test-Path $gitDir) {
        Write-Log "Repositorio git ja inicializado em $labsRoot" -Level OK
    }
    else {
        Write-Log "Repositorio git ausente. Rodando 'git init'..." -Level WARN
        Push-Location $labsRoot
        git init | Out-Null
        Pop-Location

        if (-not (Test-Path $gitDir)) {
            Write-Log "'git init' falhou." -Level FAIL
            return [PSCustomObject]@{ Name = "Git Repo"; Status = "FAIL"; Detail = "git init falhou" }
        }
        Write-Log "'git init' concluido." -Level OK
    }

    $gitignore = Join-Path $labsRoot ".gitignore"
    if (Test-Path $gitignore) {
        Write-Log ".gitignore presente." -Level OK
        return [PSCustomObject]@{ Name = "Git Repo"; Status = "OK"; Detail = "init + .gitignore OK" }
    }

    Write-Log ".gitignore ausente em $labsRoot - crie manualmente (o script nao gera um, para nao sobrescrever regras existentes)." -Level WARN
    return [PSCustomObject]@{ Name = "Git Repo"; Status = "WARN"; Detail = "sem .gitignore" }
}
