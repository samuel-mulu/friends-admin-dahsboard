param(
  [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $EnvFile)) {
  Write-Error @"
Missing $EnvFile.

For release builds, copy .env.production.example to .env:
  Copy-Item .env.production.example .env
"@
  exit 1
}

$content = Get-Content $EnvFile -Raw
if ($content -match '(?i)(localhost|127\.0\.0\.1|10\.0\.2\.2)') {
  Write-Error @"
Release builds cannot use local URLs in $EnvFile.

Copy production values from .env.production.example:
  Copy-Item .env.production.example .env
"@
  exit 1
}

Write-Host "Building release APK with bundled $EnvFile ..."
flutter build apk --release @args
