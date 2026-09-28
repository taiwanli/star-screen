# 星映 Windows 打包（docs/12）
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host '== flutter pub get =='
flutter pub get

Write-Host '== analyze / test =='
dart analyze
if ($LASTEXITCODE -ne 0) { throw 'analyze failed' }
dart test packages/domain packages/player packages/storage packages/plugins packages/lan
if ($LASTEXITCODE -ne 0) { throw 'tests failed' }

Write-Host '== build windows =='
Push-Location apps/desktop
flutter build windows --release
Pop-Location

$rel = Join-Path $root 'apps\desktop\build\windows\x64\runner\Release'
Write-Host "产物: $rel"
Get-ChildItem $rel | Select-Object Name, Length
