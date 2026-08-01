function Step-DockerDesktop {
    Write-Log "Step 4/10 - Docker Desktop" -Level STEP

    $cmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Log "Docker CLI nao encontrado. Instalando Docker Desktop via winget..." -Level WARN
        winget install --id Docker.DockerDesktop -e --accept-source-agreements --accept-package-agreements | Out-Null
        Write-Log "Docker Desktop instalado. Abra-o manualmente uma vez (aceitar licenca, habilitar backend WSL2) antes de rodar este script de novo." -Level WARN
        return [PSCustomObject]@{ Name = "Docker Desktop"; Status = "WARN"; Detail = "instalado, requer 1a abertura manual" }
    }

    Write-Log "Docker CLI encontrado: $(docker --version)" -Level OK

    docker run --rm hello-world *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "'docker run hello-world' OK - daemon respondendo." -Level OK
        return [PSCustomObject]@{ Name = "Docker Desktop"; Status = "OK"; Detail = "hello-world OK" }
    }

    Write-Log "Docker CLI presente mas o daemon nao respondeu. Abra o Docker Desktop e aguarde o icone ficar 'Running', depois rode o script de novo." -Level FAIL
    return [PSCustomObject]@{ Name = "Docker Desktop"; Status = "FAIL"; Detail = "daemon nao respondeu" }
}
