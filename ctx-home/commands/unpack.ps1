#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0, Mandatory = $true)][string]$ArchivePath,
    [switch]$Merge,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')

if (-not (Test-Path $ArchivePath)) { throw "Archive not found: $ArchivePath" }
$atCtx = Find-AtCtxDir
$projectsDir = Join-Path $atCtx 'projects'
if (-not (Test-Path $projectsDir)) { New-Item -ItemType Directory -Path $projectsDir -Force | Out-Null }
$extract = Join-Path (Split-Path -Parent $ArchivePath) ('.ctx-unpack-staging-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $extract -Force | Out-Null

try {
    Expand-Archive -Path $ArchivePath -DestinationPath $extract -Force
    $metaFile = Join-Path $extract 'handoff.json'
    if (-not (Test-Path $metaFile)) { throw 'Archive is missing handoff.json' }
    $meta = Get-Content $metaFile -Raw | ConvertFrom-Json
    $target = Join-Path $projectsDir $meta.project
    $source = Join-Path $extract 'context'
    if (-not (Test-Path $source)) { throw 'Archive is missing context payload' }

    if ((Test-Path $target) -and -not $Merge -and -not $Force) {
        throw "Context already exists at $target. Use --merge or --force."
    }
    if ($Force -and (Test-Path $target)) { Remove-Item $target -Recurse -Force }
    if (-not (Test-Path $target)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }

    if ($Merge) {
        Copy-Item (Join-Path $source '*') $target -Recurse -Force
    } else {
        if (Test-Path $target) { Remove-Item $target -Recurse -Force }
        Copy-Item $source $target -Recurse -Force
    }
    Write-Host "Restored context for $($meta.project) to $target" -ForegroundColor Green
} finally {
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
}
