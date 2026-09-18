# scripts/start_mobile.ps1
$ErrorActionPreference = "Stop"

Write-Host "== BOOKALO MOBILE START =="

# =========================
# CONFIG
# =========================

$RepoRoot   = (Resolve-Path "$PSScriptRoot\..").Path
$AvdName    = "Pixel_6"
$DeviceId   = "emulator-5554"
$ApiBaseUrl = "http://10.0.2.2:8090/api/v1"

$AndroidSdk  = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$EmulatorExe = Join-Path $AndroidSdk "emulator\emulator.exe"
$AdbExe      = Join-Path $AndroidSdk "platform-tools\adb.exe"

Write-Host "-> Repo: $RepoRoot"

# =========================
# CHECKS
# =========================

if (-not (Test-Path $EmulatorExe)) {
    throw "emulator.exe non trovato: $EmulatorExe"
}

if (-not (Test-Path $AdbExe)) {
    throw "adb.exe non trovato: $AdbExe"
}

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "Repository Git non trovato in: $RepoRoot"
}

# =========================
# 1) GIT PULL
# =========================

Write-Host "-> git pull --ff-only"

git -C $RepoRoot pull --ff-only

if ($LASTEXITCODE -ne 0) {
    throw "git pull fallito"
}

# =========================
# 2) EMULATOR
# =========================

$devices = & $AdbExe devices

$alreadyOnline = $devices -match $DeviceId

if (-not $alreadyOnline) {
    Write-Host "-> Starting AVD '$AvdName'"

    Start-Process `
        -FilePath $EmulatorExe `
        -ArgumentList @("-avd", $AvdName)
}
else {
    Write-Host "-> Emulator gia online ($DeviceId)"
}

Write-Host "-> devices:"
& $AdbExe devices

# =========================
# 3) BACKUP GPT
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
            Write-Warning "$Label terminato con exit code $LASTEXITCODE. Continuo comunque."
        }
    }
    catch {
        Write-Warning "$Label fallito: $($_.Exception.Message). Continuo comunque."
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
# 4) WAIT FOR ANDROID
# =========================

Write-Host "-> Waiting for device..."
& $AdbExe wait-for-device | Out-Null

Write-Host "-> Waiting for Android boot..."

$booted = $false

for ($i = 0; $i -lt 180; $i++) {

    try {
        $boot = (& $AdbExe shell getprop sys.boot_completed 2>$null | Out-String).Trim()

        if ($boot -eq "1") {
            $booted = $true
            break
        }
    }
    catch {
    }

    Start-Sleep -Seconds 1
}

if (-not $booted) {
    Write-Warning "Boot Android non confermato dopo 180 secondi. Procedo comunque."
}
else {
    Write-Host "-> Device ready!"
}

# =========================
# 5) FLUTTER RUN
# =========================

Set-Location $RepoRoot

Write-Host "-> flutter run -d $DeviceId --dart-define=API_BASE_URL=$ApiBaseUrl"

flutter run `
    -d $DeviceId `
    --dart-define=API_BASE_URL=$ApiBaseUrl

Write-Host ""
Write-Host "== BOOKALO MOBILE START END =="
Write-Host "Nota: dopo CTRL+C esegui:"
Write-Host "powershell -ExecutionPolicy Bypass -File .\scripts\stop_mobile.ps1"