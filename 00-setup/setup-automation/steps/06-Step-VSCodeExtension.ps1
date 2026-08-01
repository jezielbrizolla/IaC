function Step-VSCodeExtension {
    Write-Log "Step 6/9 - Extensao VS Code (HashiCorp Terraform)" -Level STEP

    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if (-not $codeCmd) {
        Write-Log "Comando 'code' nao encontrado no PATH. Pulando verificacao - instale a extensao manualmente pelo VS Code (Ctrl+Shift+X)." -Level WARN
        return [PSCustomObject]@{ Name = "VS Code Extension"; Status = "WARN"; Detail = "'code' CLI ausente" }
    }

    $extensions = & code --list-extensions 2>$null
    if ($extensions -match "(?i)hashicorp\.terraform") {
        Write-Log "Extensao HashiCorp Terraform ja instalada." -Level OK
        return [PSCustomObject]@{ Name = "VS Code Extension"; Status = "OK"; Detail = "hashicorp.terraform presente" }
    }

    Write-Log "Extensao ausente. Instalando..." -Level WARN
    & code --install-extension hashicorp.terraform | Out-Null

    $extensions = & code --list-extensions 2>$null
    if ($extensions -match "(?i)hashicorp\.terraform") {
        Write-Log "Extensao instalada com sucesso." -Level OK
        return [PSCustomObject]@{ Name = "VS Code Extension"; Status = "OK"; Detail = "instalada nesta execucao" }
    }

    Write-Log "Nao foi possivel confirmar a instalacao da extensao." -Level FAIL
    return [PSCustomObject]@{ Name = "VS Code Extension"; Status = "FAIL"; Detail = "instalacao nao confirmada" }
}
