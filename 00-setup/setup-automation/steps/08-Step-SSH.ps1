function Test-SshAuthOutput {
    param([string]$Text)
    return $Text -match "successfully authenticated"
}

function Step-SSH {
    Write-Log "Step 8/9 - Autenticacao SSH com GitHub" -Level STEP

    $results = @()

    # --- Windows / Git Bash ---
    $sshCmd = Get-Command ssh -ErrorAction SilentlyContinue
    if ($sshCmd) {
        $out = & ssh -T git@github.com 2>&1
        $text = ($out | Out-String)
        if (Test-SshAuthOutput -Text $text) {
            Write-Log "SSH (Windows) autenticado com sucesso no GitHub." -Level OK
            $results += [PSCustomObject]@{ Name = "SSH Windows"; Status = "OK"; Detail = "autenticado" }
        }
        else {
            Write-Log "SSH (Windows) NAO autenticou. Configure a chave 'ssh-iac' e cadastre a .pub no GitHub (Settings > SSH keys)." -Level FAIL
            $results += [PSCustomObject]@{ Name = "SSH Windows"; Status = "FAIL"; Detail = "nao autenticado" }
        }
    }
    else {
        Write-Log "ssh.exe nao encontrado no Windows (instale o OpenSSH Client via Settings > Optional Features)." -Level WARN
        $results += [PSCustomObject]@{ Name = "SSH Windows"; Status = "WARN"; Detail = "ssh ausente" }
    }

    # --- WSL Ubuntu ---
    $wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
    if ($wslCmd) {
        $wslOut = & wsl -d Ubuntu -- bash -lc "ssh -T git@github.com 2>&1"
        $wslText = ($wslOut | Out-String)
        if (Test-SshAuthOutput -Text $wslText) {
            Write-Log "SSH (WSL Ubuntu) autenticado com sucesso no GitHub." -Level OK
            $results += [PSCustomObject]@{ Name = "SSH WSL"; Status = "OK"; Detail = "autenticado" }
        }
        else {
            Write-Log "SSH (WSL Ubuntu) NAO autenticou. Rode 'bash 00-setup/wsl-ssh-setup.sh' dentro do WSL e configure a chave la tambem." -Level WARN
            $results += [PSCustomObject]@{ Name = "SSH WSL"; Status = "WARN"; Detail = "nao autenticado ou distro ausente" }
        }
    }
    else {
        $results += [PSCustomObject]@{ Name = "SSH WSL"; Status = "WARN"; Detail = "wsl ausente" }
    }

    return $results
}
