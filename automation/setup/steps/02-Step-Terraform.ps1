function Step-Terraform {
    Write-Log "Step 2/10 - Terraform" -Level STEP

    $cmd = Get-Command terraform -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (& terraform -version | Select-Object -First 1)
        Write-Log "Terraform ja instalado: $ver" -Level OK
        return [PSCustomObject]@{ Name = "Terraform"; Status = "OK"; Detail = $ver }
    }

    Write-Log "Terraform nao encontrado. Instalando via winget (Hashicorp.Terraform)..." -Level WARN
    winget install --id Hashicorp.Terraform -e --accept-source-agreements --accept-package-agreements | Out-Null

    $cmd = Get-Command terraform -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (& terraform -version | Select-Object -First 1)
        Write-Log "Terraform instalado com sucesso: $ver" -Level OK
        return [PSCustomObject]@{ Name = "Terraform"; Status = "OK"; Detail = $ver }
    }

    Write-Log "Terraform ainda nao aparece no PATH desta sessao. Abra um terminal NOVO e rode 'terraform -version'." -Level FAIL
    return [PSCustomObject]@{ Name = "Terraform"; Status = "FAIL"; Detail = "nao encontrado apos instalacao - abra sessao nova" }
}
