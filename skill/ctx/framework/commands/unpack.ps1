#!/usr/bin/env pwsh
# ctx unpack - Restore context from a handoff archive
# Usage: ctx unpack <archive-path> [target-dir]
#
# Unpacks a ctx handoff archive created by 'ctx pack'
# Restores .ctx/ directory and .ctxconfig
#
# Options:
#   --merge    Merge with existing context (default: fail if exists)
#   --force    Overwrite existing context without prompting

param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$ArchivePath,
    
    [Parameter(Position = 1)]
    [string]$TargetDir,
    
    [switch]$Merge,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Validate archive exists
if (-not (Test-Path $ArchivePath)) {
    Write-Error "Archive not found: $ArchivePath"
    exit 1
}

# Default target is current directory
if (-not $TargetDir) {
    $TargetDir = Get-Location
}

# Resolve to absolute path
$TargetDir = (Resolve-Path $TargetDir -ErrorAction SilentlyContinue) ?? $TargetDir

$ctxTarget = Join-Path $TargetDir ".ctx"
$configTarget = Join-Path $TargetDir ".ctxconfig"

Write-Host "Unpacking context handoff..." -ForegroundColor Cyan
Write-Host "  Archive: $ArchivePath" -ForegroundColor Gray
Write-Host "  Target:  $TargetDir" -ForegroundColor Gray

# Check for existing context
if ((Test-Path $ctxTarget) -and -not $Force -and -not $Merge) {
    Write-Host ""
    Write-Host "WARNING: Context already exists at target!" -ForegroundColor Yellow
    Write-Host "  $ctxTarget" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  --force   Overwrite existing context" -ForegroundColor Gray
    Write-Host "  --merge   Merge with existing (keeps both, may conflict)" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Create temp extraction directory
$extractDir = Join-Path ([System.IO.Path]::GetTempPath()) "ctx-unpack-$(Get-Random)"
New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

try {
    # Extract archive
    Expand-Archive -Path $ArchivePath -DestinationPath $extractDir -Force
    
    # Read handoff metadata
    $handoffPath = Join-Path $extractDir "handoff.json"
    $handoff = $null
    if (Test-Path $handoffPath) {
        $handoff = Get-Content $handoffPath -Raw | ConvertFrom-Json
        Write-Host ""
        Write-Host "Handoff info:" -ForegroundColor Gray
        Write-Host "  Packed at: $($handoff.packed_at)" -ForegroundColor DarkGray
        Write-Host "  Packed by: $($handoff.packed_by) on $($handoff.packed_from)" -ForegroundColor DarkGray
        Write-Host "  Project:   $($handoff.project)" -ForegroundColor DarkGray
        if ($handoff.git_branch) {
            Write-Host "  Branch:    $($handoff.git_branch)" -ForegroundColor DarkGray
        }
        if ($handoff.notes) {
            Write-Host "  Notes:     $($handoff.notes)" -ForegroundColor DarkGray
        }
    }
    
    # Handle existing context
    if ($Force -and (Test-Path $ctxTarget)) {
        Write-Host ""
        Write-Host "Removing existing context..." -ForegroundColor Yellow
        Remove-Item -Path $ctxTarget -Recurse -Force
    }
    
    # Copy .ctx directory
    $extractedCtx = Join-Path $extractDir ".ctx"
    if (Test-Path $extractedCtx) {
        if ($Merge -and (Test-Path $ctxTarget)) {
            Write-Host ""
            Write-Host "Merging context..." -ForegroundColor Cyan
            # Simple merge: copy files that don't exist
            Get-ChildItem -Path $extractedCtx -Recurse -File | ForEach-Object {
                $relativePath = $_.FullName.Substring($extractedCtx.Length + 1)
                $destPath = Join-Path $ctxTarget $relativePath
                $destDir = Split-Path -Parent $destPath
                
                if (-not (Test-Path $destPath)) {
                    if (-not (Test-Path $destDir)) {
                        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                    }
                    Copy-Item -Path $_.FullName -Destination $destPath
                    Write-Host "  + $relativePath" -ForegroundColor Green
                } else {
                    Write-Host "  ~ $relativePath (exists, skipped)" -ForegroundColor DarkGray
                }
            }
        } else {
            Copy-Item -Path $extractedCtx -Destination $ctxTarget -Recurse -Force
        }
    }
    
    # Copy .ctxconfig if exists and target doesn't have one
    $extractedConfig = Join-Path $extractDir ".ctxconfig"
    if ((Test-Path $extractedConfig) -and (-not (Test-Path $configTarget) -or $Force)) {
        Copy-Item -Path $extractedConfig -Destination $configTarget -Force
        Write-Host "  Restored .ctxconfig" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Context unpacked successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  ctx start    # Resume iteration" -ForegroundColor Yellow
    Write-Host "  ctx state    # View current state" -ForegroundColor Yellow
    Write-Host "  ctx todos    # Check pending work" -ForegroundColor Yellow
    
} finally {
    # Cleanup
    if (Test-Path $extractDir) {
        Remove-Item -Path $extractDir -Recurse -Force
    }
}
