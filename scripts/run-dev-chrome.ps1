param(
  [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if (-not (Test-Path $EnvFile)) {
  Write-Host "Missing $EnvFile — copying from .env.example ..."
  Copy-Item .env.example $EnvFile
}

Write-Host "Running on Chrome with $EnvFile ..."
flutter run -d chrome --dart-define-from-file=$EnvFile @args
