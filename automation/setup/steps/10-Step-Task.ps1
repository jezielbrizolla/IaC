function Step-Task {
    Write-Log "Step 10/10 - go-task (runner do Taskfile)" -Level STEP

    $cmd = Get-Command task -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (& task --version)
        Write-Log "go-task ja instalado: $ver" -Level OK
        return [PSCustomObject]@{ Name = "Task"; Status = "OK"; Detail = $ver }
    }

    Write-Log "go-task nao encontrado. Instalando via winget (Task.Task)..." -Level WARN
    winget install --id Task.Task -e --accept-source-agreements --accept-package-agreements | Out-Null

    $cmd = Get-Command task -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (& task --version)
        Write-Log "go-task instalado com sucesso: $ver" -Level OK
        return [PSCustomObject]@{ Name = "Task"; Status = "OK"; Detail = $ver }
    }

    Write-Log "go-task ainda nao aparece no PATH desta sessao. Abra um terminal NOVO e rode 'task --version'." -Level FAIL
    return [PSCustomObject]@{ Name = "Task"; Status = "FAIL"; Detail = "nao encontrado apos instalacao - abra sessao nova" }
}
