#!/usr/bin/env pwsh
# ctx index - List context files with sizes and staleness
# Usage: ./ctx index [path]
#
# Shows all files in .context (or specified path) with:
# - Size in lines (for token estimation)
# - Last modified date
# - Staleness indicator (days since modification)

param(
    [Parameter(Position=0)]
    [string]$Path
)

$ScriptRoot = Split-Path -Parent $PSScriptRoot
$ContextDir = if ($Path) { $Path } else { Join-Path $ScriptRoot ".context" }

if (-not (Test-Path $ContextDir)) {
    Write-Host "NO CONTEXT DIRECTORY FOUND" -ForegroundColor Yellow
    Write-Host "Expected: $ContextDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "This may mean:" -ForegroundColor Gray
    Write-Host "  - You're in the wrong directory" -ForegroundColor Gray
    Write-Host "  - Context hasn't been initialized yet" -ForegroundColor Gray
    Write-Host "  - Specify a path: ./ctx index /path/to/.context" -ForegroundColor Gray
    exit 1
}

$now = Get-Date

function Get-Staleness {
    param([DateTime]$Modified)
    $days = ($now - $Modified).Days
    switch ($days) {
        { $_ -eq 0 } { return @{ text = "today"; color = "Green" } }
        { $_ -eq 1 } { return @{ text = "1 day"; color = "Green" } }
        { $_ -le 7 } { return @{ text = "$_ days"; color = "Yellow" } }
        { $_ -le 30 } { return @{ text = "$_ days"; color = "DarkYellow" } }
        default { return @{ text = "$_ days"; color = "Red" } }
    }
}

function Get-LineCount {
    param([string]$FilePath)
    try {
        return (Get-Content $FilePath -ErrorAction Stop | Measure-Object -Line).Lines
    } catch {
        return "?"
    }
}

Write-Host ""
Write-Host "CONTEXT INDEX: $ContextDir" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor DarkGray
Write-Host ""

# Get all files recursively
$files = Get-ChildItem -Path $ContextDir -Recurse -File | Sort-Object DirectoryName, Name

$currentDir = ""
$totalLines = 0
$fileCount = 0

foreach ($file in $files) {
    $relDir = $file.DirectoryName.Replace($ContextDir, "").TrimStart('\', '/')
    
    # Print directory header if changed
    if ($relDir -ne $currentDir) {
        if ($currentDir -ne "") { Write-Host "" }
        $displayDir = if ($relDir) { "/$relDir/" } else { "/" }
        Write-Host $displayDir -ForegroundColor Yellow
        $currentDir = $relDir
    }
    
    $lines = Get-LineCount $file.FullName
    $staleness = Get-Staleness $file.LastWriteTime
    $modified = $file.LastWriteTime.ToString("yyyy-MM-dd")
    
    if ($lines -ne "?") { $totalLines += $lines }
    $fileCount++
    
    # Format: "  filename.md          142 lines   2025-12-01   (5 days)"
    $name = $file.Name
    $lineStr = if ($lines -eq "?") { "? lines" } else { "$lines lines" }
    
    Write-Host "  " -NoNewline
    Write-Host $name.PadRight(28) -NoNewline -ForegroundColor White
    Write-Host $lineStr.PadLeft(10) -NoNewline -ForegroundColor Gray
    Write-Host "   $modified   " -NoNewline -ForegroundColor DarkGray
    Write-Host "($($staleness.text))" -ForegroundColor $staleness.color
}

Write-Host ""
Write-Host ("=" * 70) -ForegroundColor DarkGray
Write-Host "Total: $fileCount files, ~$totalLines lines (~$([math]::Round($totalLines * 1.3)) tokens est.)" -ForegroundColor Cyan
Write-Host ""

# Provide reading order suggestion based on staleness and importance
$priorityFiles = @(
    "projectObjectives.md",
    "changeLog.md", 
    "README.md"
)

$found = $files | Where-Object { $priorityFiles -contains $_.Name }
if ($found) {
    Write-Host "SUGGESTED READING ORDER:" -ForegroundColor Yellow
    foreach ($pf in $priorityFiles) {
        $match = $found | Where-Object { $_.Name -eq $pf }
        if ($match) {
            $lines = Get-LineCount $match.FullName
            $staleness = Get-Staleness $match.LastWriteTime
            Write-Host "  1. $pf ($lines lines, $($staleness.text) old)" -ForegroundColor Gray
        }
    }
    Write-Host ""
}
