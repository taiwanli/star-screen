# 星映 Android 打包（docs/12）· 用法: package-android.ps1 [-App mobile|tv]
param(
  [ValidateSet('mobile', 'tv')]
  [string]$App = 'mobile'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location (Join-Path $root "apps\$App")

Write-Host "== flutter pub get ($App) =="
flutter pub get

Write-Host '== build apk =='
flutter build apk --release

$out = Join-Path $root "apps\$App\build\app\outputs\flutter-apk\app-release.apk"
Write-Host "产物: $out"
if (Test-Path $out) { Get-Item $out | Select-Object FullName, Length }
