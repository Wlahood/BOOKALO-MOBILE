$ANDROID_SDK = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$ADB         = Join-Path $ANDROID_SDK "platform-tools\adb.exe"
$EMULATOR    = Join-Path $ANDROID_SDK "emulator\emulator.exe"

if (!(Test-Path $ADB)) {
  Write-Host "ERRORE: adb.exe non trovato in: $ADB" -ForegroundColor Red
  exit 1
}
if (!(Test-Path $EMULATOR)) {
  Write-Host "ERRORE: emulator.exe non trovato in: $EMULATOR" -ForegroundColor Red
  exit 1
}

# scripts/start_mobile.ps1
$ErrorActionPreference = "Stop"

Write-Host "== BOOKALO MOBILE START =="

# vai alla root repo (uno su dalla cartella scripts)
Set-Location (Resolve-Path "$PSScriptRoot\..")

# --- CONFIG ---
$AvdName    = "Pixel_6"
$DeviceId   = "emulator-5554"
$ApiBaseUrl = "http://10.0.2.2:8090/api/v1"

# Android SDK paths
$AndroidSdk  = "$env:LOCALAPPDATA\Android\Sdk"
$EmulatorExe = Join-Path $AndroidSdk "emulator\emulator.exe"
$AdbExe      = Join-Path $AndroidSdk "platform-tools\adb.exe"

# 1) Git pull
Write-Host "-> git pull"
git pull

# 2) Avvia emulator (se non già online)
if (-not (Test-Path $EmulatorExe)) {
  throw "emulator.exe non trovato: $EmulatorExe (controlla Android SDK)"
}
if (-not (Test-Path $AdbExe)) {
  throw "adb.exe non trovato: $AdbExe (controlla Android SDK platform-tools)"
}

# controlla se già c'è un device online
$devices = & $AdbExe devices
$alreadyOnline = $devices -match $DeviceId

if (-not $alreadyOnline) {
  Write-Host "-> Starting AVD '$AvdName'"
  Start-Process -FilePath $EmulatorExe -ArgumentList @("-avd", $AvdName)
} else {
  Write-Host "-> Emulator già online ($DeviceId)"
}

Write-Host "-> devices:"
& $AdbExe devices

# 2) Backup GTP
$backupGptPs1  = ".\scripts\backup_bookalo_mobile_gpt.ps1"

if (Test-Path $backupGptPs1) {
  Invoke-BackupSafely "backup_bookalo_mobile_gpt.ps1" { powershell -ExecutionPolicy Bypass -File $backupGptPs1 }
} else {
  Write-Warning "backup_bookalo_mobile_gpt.ps1 non trovato (skip)"
}


# 3) Wait for device
Write-Host "-> wait-for-device"
& $AdbExe wait-for-device | Out-Null

Write-Host "-> Waiting for Android boot (sys.boot_completed=1)..."
do {
  Start-Sleep -Seconds 2
  $boot = & $AdbExe shell getprop sys.boot_completed 2>$null
  Write-Host "   boot_completed=$boot"
} until ($boot -match "1")

Write-Host "-> Device ready!"

# 4) Wait boot complete
Write-Host "-> Waiting for Android boot to complete..."
$booted = $false
for ($i=0; $i -lt 180; $i++) {
  try {
    $v = & $AdbExe shell getprop sys.boot_completed 2>$null
    if (($v | Out-String).Trim() -eq "1") { $booted = $true; break }
  } catch {}
  Start-Sleep -Seconds 1
}
if (-not $booted) {
  Write-Warning "Boot non confermato dopo ~180s, procedo comunque..."
} else {
  Write-Host "-> Boot OK"
}

# 6) flutter run (il tuo comando ESATTO)
Write-Host "-> flutter run -d $DeviceId --dart-define=API_BASE_URL=$ApiBaseUrl"
flutter run -d $DeviceId --dart-define=API_BASE_URL=$ApiBaseUrl

Write-Host "== BOOKALO MOBILE START END =="
Write-Host "Nota: quando chiudi con CTRL+C, poi lancia lo stop: powershell -ExecutionPolicy Bypass -File .\scripts\stop_mobile.ps1"