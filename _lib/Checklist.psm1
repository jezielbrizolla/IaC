# Marca itens de um CHECKLIST.md como [x] com base no que um orquestrador de
# lab validou de fato nesta execucao. Nunca desmarca um item ja marcado
# manualmente. Reusado por 00-setup/setup-automation e pelo run.ps1 de cada
# lab - cada chamador passa o PatternMap especifico do seu CHECKLIST.md.

function Update-SetupChecklist {
    param(
        [Parameter(Mandatory)][string]$ChecklistPath,
        [Parameter(Mandatory)]$Results,
        # Pattern (regex, aplicado a linha do checklist) -> Name do resultado
        # que precisa estar Status=OK para a linha virar [x]. Se omitido, usa
        # o mapa do 00-setup (compatibilidade com o orquestrador original).
        [Parameter()]$PatternMap
    )

    if (-not (Test-Path $ChecklistPath)) {
        Write-Log "CHECKLIST.md nao encontrado em $ChecklistPath - pulando atualizacao automatica." -Level WARN
        return
    }

    if (-not $PatternMap) {
        $PatternMap = @(
            @{ Pattern = "Instalar Terraform";                  Result = "Terraform" }
            @{ Pattern = "Instalar Packer";                     Result = "Packer" }
            @{ Pattern = "Instalar Docker Desktop";              Result = "Docker Desktop" }
            @{ Pattern = "Habilitar integra";                    Result = "Docker Desktop" }
            @{ Pattern = "Instalar extens";                      Result = "VS Code Extension" }
            @{ Pattern = "Inicializar reposit";                  Result = "Git Repo" }
            @{ Pattern = "ssh-iac.*Ubuntu WSL";                  Result = "SSH WSL" }
            @{ Pattern = "ssh-iac.*PowerShell";                  Result = "SSH Windows" }
            @{ Pattern = "ssh -T git@github\.com.*Windows";      Result = "SSH Windows" }
            @{ Pattern = "ssh -T git@github\.com.*WSL";          Result = "SSH WSL" }
            @{ Pattern = "repositorio remoto";                   Result = "Git Remote" }
            @{ Pattern = "origin";                                Result = "Git Remote" }
            @{ Pattern = "Validar .terraform -version";          Result = "Terraform" }
            @{ Pattern = "Validar .packer version";              Result = "Packer" }
            @{ Pattern = "Validar .docker run hello-world";      Result = "Docker Desktop" }
        )
    }
    $map = $PatternMap

    $lines = Get-Content -Path $ChecklistPath -Encoding UTF8
    $changed = $false
    $newLines = New-Object System.Collections.Generic.List[string]

    foreach ($line in $lines) {
        $updatedLine = $line
        if ($line -match '^\-\s\[\s\]') {
            foreach ($m in $map) {
                if ($line -match $m.Pattern) {
                    $r = $Results | Where-Object { $_.Name -eq $m.Result }
                    if ($r -and $r.Status -eq "OK") {
                        $candidate = $line -replace '^\-\s\[\s\]', '- [x]'
                        if ($candidate -ne $line) {
                            $updatedLine = $candidate
                            Write-Log "Checklist atualizado: '$($line.Trim())'" -Level OK
                            $changed = $true
                        }
                        break
                    }
                }
            }
        }
        $newLines.Add($updatedLine)
    }

    if ($changed) {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllLines($ChecklistPath, $newLines, $utf8NoBom)
        Write-Log "CHECKLIST.md salvo com os itens validados automaticamente." -Level OK
    }
    else {
        Write-Log "Nenhum item novo para marcar no CHECKLIST.md." -Level INFO
    }
}

Export-ModuleMember -Function Update-SetupChecklist
