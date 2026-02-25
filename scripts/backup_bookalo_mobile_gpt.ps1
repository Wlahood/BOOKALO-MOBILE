param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-Timestamp {
  return (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
}

$ts = Get-Timestamp
$outDir = Join-Path $ProjectRoot "_backups"
$stageDir = Join-Path $outDir ".tmp_bookalo_mobile_GPT_$ts"
$outFile = Join-Path $outDir "bookalo_mobile_GPT_$ts.tar.gz"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

Write-Host "== BOOKALO MOBILE GPT BACKUP =="
Write-Host "-> Root:  $ProjectRoot"
Write-Host "-> Stage: $stageDir"
Write-Host "-> Out:   $outFile"
Write-Host ""

# Excludes (common Flutter + platform caches)
$excludeDirs = @(
  ".git", ".idea", ".vscode",
  "build", ".dart_tool", ".flutter-plugins", ".flutter-plugins-dependencies",
  ".pub-cache",
  "android\.gradle", "android\build", "android\app\build",
  "ios\Pods", "ios\.symlinks", "ios\build",
  "macos\Pods", "macos\.symlinks", "macos\build",
  "linux\build", "windows\build",
  ".gradle", ".DS_Store",
  "_backups"
)

# Copy project tree lean
Write-Host "-> Copying project (lean)..."
$destProject = Join-Path $stageDir "project"
New-Item -ItemType Directory -Force -Path $destProject | Out-Null

# Robocopy is fast + reliable; we copy all and exclude heavy dirs
$excludeArgs = @()
foreach ($d in $excludeDirs) { $excludeArgs += @("/XD", (Join-Path $ProjectRoot $d)) }

# /E = include subdirs, /NFL /NDL reduce noise, /R:1 /W:1 for speed
$rc = & robocopy $ProjectRoot $destProject /E /R:1 /W:1 /NFL /NDL @excludeArgs
# Robocopy returns codes >= 8 on failure
if ($LASTEXITCODE -ge 8) {
  throw "Robocopy failed with exit code $LASTEXITCODE"
}

# Optional: remove local secrets by design
# - we keep .env.example if you have it, but remove .env / any local json keys
Write-Host "-> Removing sensitive/local-only files (best effort)..."
$sensitive = @(
  (Join-Path $destProject ".env"),
  (Join-Path $destProject "android\key.properties"),
  (Join-Path $destProject "android\app\*.jks"),
  (Join-Path $destProject "ios\Runner\GoogleService-Info.plist"),
  (Join-Path $destProject "android\app\google-services.json")
)
foreach ($p in $sensitive) {
  Get-ChildItem -Path $p -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Manifest
Write-Host "-> Writing manifest..."
@"
BOOKALO MOBILE GPT BACKUP (lean)
Created at: $(Get-Date -Format o)
Root: $ProjectRoot

Included:
- Flutter sources: lib/, test/, assets/, pubspec.yaml, pubspec.lock, analysis_options.yaml
- Platform folders: android/, ios/, macos/, linux/, windows/, web/ (if present)
- Tooling configs: e.g. l10n.yaml, build.yaml, etc. (if present)

Excluded (main):
- build/, .dart_tool/, .pub-cache, .gradle
- iOS Pods/, Derived data equivalents
- Android build/.gradle caches
- .git/, IDE folders, _backups/

Secrets removed (best effort):
- .env
- android key.properties / *.jks
- firebase config files (google-services.json / GoogleService-Info.plist)
"@ | Set-Content -Encoding UTF8 (Join-Path $stageDir "MANIFEST.txt")

# Create tar.gz (requires tar available: Windows 10/11 has bsdtar)
Write-Host "-> Creating archive..."
Push-Location $stageDir
try {
  & tar -czf $outFile .
} finally {
  Pop-Location
}

Write-Host "-> Cleaning stage..."
Remove-Item -Recurse -Force $stageDir

Write-Host ""
Write-Host "✅ Done: $outFile"