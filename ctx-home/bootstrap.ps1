#!/usr/bin/env pwsh
param(
    [switch]$Status,
    [switch]$Remove,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$FrameworkDir = $PSScriptRoot
$AtCtxDir = Join-Path $FrameworkDir '@ctx'
$RegistryFile = Join-Path $AtCtxDir 'registry.json'
$ProjectsDir = Join-Path $AtCtxDir 'projects'

function Ensure-HomeContext {
    if (-not (Test-Path $ProjectsDir)) {
        New-Item -ItemType Directory -Path $ProjectsDir -Force | Out-Null
    }
    if (-not (Test-Path $RegistryFile)) {
        $registry = [ordered]@{
            version = '1.0.0'
            projects = [ordered]@{}
        }
        $registry | ConvertTo-Json -Depth 10 | Set-Content $RegistryFile -Encoding UTF8
    }
}

if ($Help) {
    Write-Host 'ctx bootstrap - initialize home ctx runtime files and PATH'
    Write-Host ''
    Write-Host '  .\bootstrap.ps1           create @ctx runtime store and print next steps'
    Write-Host '  .\bootstrap.ps1 -Status   show runtime and PATH status'
    Write-Host '  .\bootstrap.ps1 -Remove   remove this folder from User PATH'
    exit 0
}

if ($Remove) {
    $currentUserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $entries = $currentUserPath -split ';' | Where-Object { $_ }
    $newPath = ($entries | Where-Object { $_ -ne $FrameworkDir }) -join ';'
    [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
    Write-Host 'Removed ctx-home from User PATH.' -ForegroundColor Yellow
    exit 0
}

Ensure-HomeContext

if ($Status) {
    $currentUserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $inUserPath = ($currentUserPath -split ';') -contains $FrameworkDir
    Write-Host 'CTX HOME STATUS' -ForegroundColor Cyan
    Write-Host "  Package:   $FrameworkDir"
    Write-Host "  Runtime:   $AtCtxDir"
    Write-Host "  Registry:  $RegistryFile"
    Write-Host "  In PATH:   $(if ($inUserPath) { 'yes' } else { 'no' })"
    exit 0
}

$currentUserPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$entries = $currentUserPath -split ';' | Where-Object { $_ }
if ($entries -notcontains $FrameworkDir) {
    [Environment]::SetEnvironmentVariable('PATH', (($entries + $FrameworkDir) -join ';'), 'User')
}

Write-Host 'ctx home initialized.' -ForegroundColor Green
Write-Host "  Runtime: $AtCtxDir" -ForegroundColor Gray
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1. Open a new terminal' -ForegroundColor Gray
Write-Host '  2. Run: ctx register' -ForegroundColor Gray
Write-Host '  3. Run: ctx chart' -ForegroundColor Gray
