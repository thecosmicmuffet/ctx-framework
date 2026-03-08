#!/usr/bin/env pwsh
# ctx pack - Create a portable handoff archive of current context
# Usage: ctx pack [output-path]
#
# Creates a zip containing:
# - .ctx/ directory contents
# - .ctxconfig (if exists)
# - Optional session notes from caller
#
# For migration between machines or handoff to another agent

param(
    [Parameter(Position = 0)]
    [string]$OutputPath,
    
    [Parameter()]
    [string]$Notes
)

$ErrorActionPreference = 'Stop'

# Find context directory
$ContextDir = $env:CTX_CONTEXT_DIR
if (-not $ContextDir -or -not (Test-Path $ContextDir)) {
    Write-Error "No context directory found. Run from a project with .ctx/"
    exit 1
}

$ProjectRoot = Split-Path -Parent $ContextDir
$ProjectName = Split-Path -Leaf $ProjectRoot

# Default output path
if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmm"
    $OutputPath = Join-Path $ProjectRoot "ctx-handoff-$timestamp.zip"
}

# Ensure .zip extension
if (-not $OutputPath.EndsWith('.zip')) {
    $OutputPath = "$OutputPath.zip"
}

Write-Host "Creating context handoff package..." -ForegroundColor Cyan
Write-Host "  Project: $ProjectName" -ForegroundColor Gray
Write-Host "  Context: $ContextDir" -ForegroundColor Gray
Write-Host "  Output:  $OutputPath" -ForegroundColor Gray

# Create temp staging directory
$stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "ctx-pack-$(Get-Random)"
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

try {
    # Copy .ctx directory
    $ctxDest = Join-Path $stagingDir ".ctx"
    Copy-Item -Path $ContextDir -Destination $ctxDest -Recurse
    
    # Copy .ctxconfig if exists
    $configPath = Join-Path $ProjectRoot ".ctxconfig"
    if (Test-Path $configPath) {
        Copy-Item -Path $configPath -Destination $stagingDir
    }
    
    # Add handoff metadata
    $handoffMeta = @{
        packed_at = (Get-Date -Format "o")
        packed_by = $env:USERNAME
        packed_from = $env:COMPUTERNAME
        project = $ProjectName
        git_branch = $null
        notes = $Notes
    }
    
    # Try to get git branch
    Push-Location $ProjectRoot
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) {
            $handoffMeta.git_branch = $branch
        }
    } catch { }
    Pop-Location
    
    $handoffMeta | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $stagingDir "handoff.json")
    
    # Create zip
    if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
    }
    
    Compress-Archive -Path "$stagingDir\*" -DestinationPath $OutputPath -Force
    
    Write-Host ""
    Write-Host "Handoff package created:" -ForegroundColor Green
    Write-Host "  $OutputPath" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To unpack on another machine:" -ForegroundColor Gray
    Write-Host "  ctx unpack $([System.IO.Path]::GetFileName($OutputPath))" -ForegroundColor Yellow
    
} finally {
    # Cleanup staging
    if (Test-Path $stagingDir) {
        Remove-Item -Path $stagingDir -Recurse -Force
    }
}
