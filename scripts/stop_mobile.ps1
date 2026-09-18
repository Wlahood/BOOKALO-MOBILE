# scripts/stop_mobile.ps1
$ErrorActionPreference = "Stop"

Write-Host "== BOOKALO MOBILE STOP =="

$RepoRoot = (Resolve-Path "$PSScriptRoot\..").Path

Write-Host "-> Repo: $RepoRoot"

# =========================
# CHECK GIT
# =========================

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "Repository Git non trovato in: $RepoRoot"
}

# =========================
# BACKUP
# =========================

function Invoke-BackupSafely {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    Write-Host "-> $Label"

    try {
        & $Action

        if ($LASTEXITCODE -ne 0) {
            Write-Warning "$Label terminato con exit code $LASTEXITCODE. Continuo comunque con Git."
        }
    }
    catch {
        Write-Warning "$Label fallito: $($_.Exception.Message). Continuo comunque con Git."
    }
}

$backupGptPs1 = Join-Path $RepoRoot "scripts\backup_bookalo_mobile_gpt.ps1"

if (Test-Path $backupGptPs1) {
    Invoke-BackupSafely "backup_bookalo_mobile_gpt.ps1" {
        powershell `
            -ExecutionPolicy Bypass `
            -File $backupGptPs1 `
            -ProjectRoot $RepoRoot
    }
}
else {
    Write-Warning "backup_bookalo_mobile_gpt.ps1 non trovato (skip)"
}

# =========================
# GIT STATUS
# =========================

$statusLines = git -C $RepoRoot status --porcelain
$statusText  = ($statusLines | Out-String).Trim()

if ($statusText.Length -gt 0) {

    Write-Host ""
    Write-Host "-> Modifiche rilevate:"
    git -C $RepoRoot status --short

    Write-Host ""
    Write-Host "-> git add ."
    git -C $RepoRoot add .

    if ($LASTEXITCODE -ne 0) {
        throw "git add fallito"
    }

    $msg = "MOBILE"

    Write-Host "-> git commit -m `"$msg`""
    git -C $RepoRoot commit -m "$msg"

    if ($LASTEXITCODE -ne 0) {
        throw "git commit fallito"
    }

    Write-Host "-> git push origin main"
    git -C $RepoRoot push origin main

    if ($LASTEXITCODE -ne 0) {
        throw "git push fallito"
    }

    Write-Host "-> Commit e push completati."
}
else {
    Write-Host "-> Working tree clean (skip commit/push)"
}

Write-Host ""
Write-Host "== BOOKALO MOBILE STOP COMPLETED =="