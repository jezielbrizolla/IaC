function Step-Prerequisites {
    Write-Log "Step 1/10 - Verificando pre-requisitos do orquestrador" -Level STEP

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Log "winget nao encontrado. Instale o 'App Installer' pela Microsoft Store e rode de novo." -Level FAIL
        return [PSCustomObject]@{ Name = "Prerequisites"; Status = "FAIL"; Detail = "winget ausente" }
    }
    Write-Log "winget disponivel: $(winget --version)" -Level OK

    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Log "Sessao NAO esta elevada (Administrador). Instalacoes via winget e Hyper-V exigem elevacao - reabra como Administrador se algum passo falhar." -Level WARN
        return [PSCustomObject]@{ Name = "Prerequisites"; Status = "WARN"; Detail = "sessao nao elevada" }
    }

    Write-Log "Sessao elevada (Administrador) confirmada." -Level OK
    return [PSCustomObject]@{ Name = "Prerequisites"; Status = "OK"; Detail = "winget + elevacao OK" }
}
