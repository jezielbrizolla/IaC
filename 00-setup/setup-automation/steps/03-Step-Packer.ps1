function Step-Packer {
    Write-Log "Step 3/9 - Packer" -Level STEP

    $cmd = Get-Command packer -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (& packer version)
        Write-Log "Packer ja instalado: $ver" -Level OK
        return [PSCustomObject]@{ Name = "Packer"; Status = "OK"; Detail = $ver }
    }

    Write-Log "Packer nao encontrado. Instalando via winget (Hashicorp.Packer)..." -Level WARN
    winget install --id Hashicorp.Packer -e --accept-source-agreements --accept-package-agreements | Out-Null

    $cmd = Get-Command packer -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (& packer version)
        Write-Log "Packer instalado com sucesso: $ver" -Level OK
        return [PSCustomObject]@{ Name = "Packer"; Status = "OK"; Detail = $ver }
    }

    Write-Log "Packer ainda nao aparece no PATH desta sessao. Abra um terminal NOVO e rode 'packer version'." -Level FAIL
    return [PSCustomObject]@{ Name = "Packer"; Status = "FAIL"; Detail = "nao encontrado apos instalacao - abra sessao nova" }
}
