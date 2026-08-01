function Step-WSLUbuntu {
    Write-Log "Step 5/9 - WSL2 + distro Ubuntu" -Level STEP

    $wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
    if (-not $wslCmd) {
        Write-Log "Comando 'wsl' nao encontrado. WSL nao parece instalado." -Level FAIL
        return [PSCustomObject]@{ Name = "WSL Ubuntu"; Status = "FAIL"; Detail = "wsl.exe ausente" }
    }

    $raw = & wsl -l -v 2>$null
    # 'wsl -l -v' as vezes sai em UTF-16 com espacos entre caracteres dependendo
    # do console; normalizamos removendo tudo que nao for letra/numero antes de comparar.
    $compact = (($raw -join "") -replace '[^\p{L}\p{N}]', '')

    if ($compact -match "(?i)ubuntu") {
        Write-Log "Distro Ubuntu encontrada no WSL." -Level OK
        return [PSCustomObject]@{ Name = "WSL Ubuntu"; Status = "OK"; Detail = "Ubuntu presente" }
    }

    Write-Log "Distro Ubuntu nao encontrada. Rode manualmente: wsl --install -d Ubuntu (pede reboot na primeira vez) e depois execute este script de novo." -Level WARN
    return [PSCustomObject]@{ Name = "WSL Ubuntu"; Status = "WARN"; Detail = "Ubuntu nao encontrada" }
}
