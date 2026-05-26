#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0)][string]$OutputPath,
    [string]$Notes
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')

$resolved = Resolve-CtxProject
if (-not $resolved.ProjectId) { throw "No project context found. Run 'ctx register' first." }
$contextDir = $resolved.ContextDir
$projectId = $resolved.ProjectId
$projectRoot = if ($resolved.CanonicalRoot) { $resolved.CanonicalRoot } else { Split-Path -Parent $contextDir }

if (-not $OutputPath) {
    $OutputPath = Join-Path $projectRoot ("ctx-handoff-{0}.zip" -f (Get-Date -Format 'yyyy-MM-dd-HHmm'))
}
if (-not $OutputPath.EndsWith('.zip')) { $OutputPath += '.zip' }

$staging = Join-Path $projectRoot ('.ctx-pack-staging-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging -Force | Out-Null

try {
    Copy-Item $contextDir (Join-Path $staging 'context') -Recurse -Force
    $meta = [ordered]@{
        packed_at = (Get-Date -Format 'o')
        project = $projectId
        notes = $Notes
    }
    $meta | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $staging 'handoff.json') -Encoding UTF8
    if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $OutputPath -Force
    Write-Host "Created $OutputPath" -ForegroundColor Green
} finally {
    if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
}
