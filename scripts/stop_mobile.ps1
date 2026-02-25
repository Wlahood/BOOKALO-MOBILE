# scripts/stop_mobile.ps1
$ErrorActionPreference = "Stop"

Write-Host "== BOOKALO MOBILE STOP =="

# vai alla root repo (uno su dalla cartella scripts)
Set-Location (Resolve-Path "$PSScriptRoot\..")

function Invoke-BackupSafely([string]$Label, [scriptblock]$Action) {
  Write-Host "-> $Label"
  try {
    & $Action
  } catch {
    Write-Warning "$Label fallito: $($_.Exception.Message) (continuo comunque con git)"
  }
}

# =========================
# 1) Nuovi backup PowerShell
# =========================
$backupGptPs1  = ".\scripts\backup_bookalo_mobile_gpt.ps1"

if (Test-Path $backupGptPs1) {
  Invoke-BackupSafely "backup_bookalo_mobile_gpt.ps1" { powershell -ExecutionPolicy Bypass -File $backupGptPs1 }
} else {
  Write-Warning "backup_bookalo_mobile_gpt.ps1 non trovato (skip)"
}

# =========================
# 3) Git commit/push solo se ci sono modifiche
# =========================
$statusLines = git status --porcelain
$statusText  = ($statusLines | Out-String).Trim()

if ($statusText.Length -gt 0) {
  Write-Host "-> git add ."
  git add .

  $msg = "MOBILE"
  Write-Host "-> git commit -m `"$msg`""
  git commit -m "$msg"

  Write-Host "-> git push"
  git push
} else {
  Write-Host "-> working tree clean (skip commit/push)"
}

Write-Host "== BOOKALO MOBILE STOP COMPLETED =="