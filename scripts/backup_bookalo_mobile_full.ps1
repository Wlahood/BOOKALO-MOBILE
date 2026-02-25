param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Get-Timestamp {
  return (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
}

$ts = Get-Timestamp
$outDir = Join-Path $ProjectRoot "_backups"
$stageDir = Join-Path $outDir ".tmp_bookalo_mobile_FULL_$ts"
$outFile = Join-Path $outDir "bookalo_mobile_FULL_$ts.tar.gz"

Write-Host "== BOOKALO MOBILE FULL BACKUP =="
Write-Host "-> Root:  $ProjectRoot"
Write-Host "-> Stage: $stageDir"
Write-Host "-> Out:   $outFile"
Write-Host ""

# Create backup folder
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Clean stage if exists
if (Test-Path $stageDir) {
    Remove-Item -Recurse -Force $stageDir
}

New-Item -ItemType Directory -Force -Path $stageDir | Out-Null

# Copy EVERYTHING except _backups itself
Write-Host "-> Copying full project..."

$destProject = Join-Path $stageDir "project"
New-Item -ItemType Directory -Force -Path $destProject | Out-Null

# Robocopy full mirror excluding only _backups to prevent recursion
$rc = robocopy `
    $ProjectRoot `
    $destProject `
    /E `
    /R:1 `
    /W:1 `
    /NFL `
    /NDL `
    /XD (Join-Path $ProjectRoot "_backups")

if ($LASTEXITCODE -ge 8) {
    throw "Robocopy failed with exit code $LASTEXITCODE"
}

# Manifest
Write-Host "-> Writing manifest..."

@"
BOOKALO MOBILE FULL BACKUP
Created at: $(Get-Date -Format o)
Root: $ProjectRoot

Included:
- Entire project directory
- .git
- build outputs
- .dart_tool
- Pods
- .gradle
- All platform builds
- All config and secrets

Excluded:
- _backups folder (to avoid recursion)
"@ | Set-Content -Encoding UTF8 (Join-Path $stageDir "MANIFEST.txt")

# Create tar.gz (Windows 10/11 includes tar)
Write-Host "-> Creating archive..."

Push-Location $stageDir
try {
    tar -czf $outFile .
}
finally {
    Pop-Location
}

# Cleanup
Write-Host "-> Cleaning stage..."
Remove-Item -Recurse -Force $stageDir

Write-Host ""
Write-Host "✅ FULL backup completed:"
Write-Host $outFile