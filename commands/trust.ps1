#!/usr/bin/env pwsh
# ctx trust - Report confidence levels and stability states
# Usage: ./ctx trust [path|file] [--verbose]
#
# Shows which context can be trusted (fresh), needs forgiveness (stale),
# or has been honored (stable foundation)

param(
    [Parameter(Position=0)]
    [string]$Target,

    [Parameter(Position=1)]
    [string]$Path,

    [Parameter()]
    [switch]$Detail
)

$ScriptRoot = Split-Path -Parent $PSScriptRoot
$ContextDir = if ($Path) { $Path } else { Join-Path $ScriptRoot ".context" }

if (-not (Test-Path $ContextDir)) {
    Write-Host "NO CONTEXT DIRECTORY FOUND" -ForegroundColor Yellow
    Write-Host "Expected: $ContextDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Run from project root or specify path" -ForegroundColor Gray
    exit 1
}

$now = Get-Date

# Staleness thresholds (configurable)
$FRESH_DAYS = 7
$AGING_DAYS = 30

function Get-TrustLevel {
    param([DateTime]$Modified)
    $days = ($now - $Modified).Days

    if ($days -le $FRESH_DAYS) {
        return @{
            level = "FRESH"
            color = "Green"
            confidence = "high"
            advice = "use directly"
            days = $days
        }
    } elseif ($days -le $AGING_DAYS) {
        return @{
            level = "AGING"
            color = "Yellow"
            confidence = "medium"
            advice = "validate if critical"
            days = $days
        }
    } else {
        return @{
            level = "STALE"
            color = "Red"
            confidence = "low"
            advice = "verify before acting"
            days = $days
        }
    }
}

function Format-FileEntry {
    param($File, $Trust, $ShowAdvice = $false)

    $relPath = $File.FullName.Replace($ContextDir, "").TrimStart('\', '/')
    $ageText = if ($Trust.days -eq 0) { "today" }
               elseif ($Trust.days -eq 1) { "1 day" }
               else { "$($Trust.days) days" }

    Write-Host "  $relPath" -ForegroundColor White -NoNewline
    Write-Host " " -NoNewline
    Write-Host "($ageText old)" -ForegroundColor DarkGray

    if ($ShowAdvice) {
        Write-Host "    → Confidence: $($Trust.confidence) - $($Trust.advice)" -ForegroundColor Gray
    }
}

# Check if target is specific file
if ($Target -and $Target -ne "all") {
    $targetPath = Join-Path $ContextDir $Target
    if (-not (Test-Path $targetPath)) {
        Write-Host "FILE NOT FOUND: $Target" -ForegroundColor Red
        Write-Host "Path checked: $targetPath" -ForegroundColor Gray
        exit 1
    }

    $file = Get-Item $targetPath
    $trust = Get-TrustLevel $file.LastWriteTime

    Write-Host ""
    Write-Host "TRUST REPORT: $Target" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host "Status: " -NoNewline
    Write-Host $trust.level -ForegroundColor $trust.color
    Write-Host "Last modified: $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))"
    Write-Host "Age: $($trust.days) days"
    Write-Host "Confidence: " -NoNewline -ForegroundColor Gray
    Write-Host $trust.confidence.ToUpper() -ForegroundColor $trust.color
    Write-Host ""

    Write-Host "Recommendation: " -NoNewline
    Write-Host $trust.advice -ForegroundColor $trust.color

    if ($trust.level -eq "STALE") {
        Write-Host ""
        Write-Host "This file is stale. Consider:" -ForegroundColor Yellow
        Write-Host "  1. Review contents for what's still valid" -ForegroundColor Gray
        Write-Host "  2. Update with current reality" -ForegroundColor Gray
        Write-Host "  3. Or run: ./ctx forgive $Target --reason '...'" -ForegroundColor Gray
    }

    Write-Host ""
    exit 0
}

# Show all files grouped by trust level
Write-Host ""
Write-Host "TRUST REPORT: $ContextDir" -ForegroundColor Cyan
Write-Host ("=" * 70) -ForegroundColor DarkGray
Write-Host ""

# Get all markdown and json files
$files = Get-ChildItem -Path $ContextDir -Recurse -File -Include "*.md","*.json" |
         Where-Object { $_.Name -notmatch "^\.forgiveness" } |
         Sort-Object LastWriteTime -Descending

# Check for honored directory
$honoredDir = Join-Path $ContextDir "honored"
$hasHonored = Test-Path $honoredDir

# Categorize files
$fresh = @()
$aging = @()
$stale = @()
$honored = @()

foreach ($file in $files) {
    $trust = Get-TrustLevel $file.LastWriteTime

    # Check if file is in honored/ subdirectory
    if ($file.FullName -like "*\honored\*" -or $file.FullName -like "*/honored/*") {
        $honored += @{ file = $file; trust = $trust }
    } else {
        switch ($trust.level) {
            "FRESH" { $fresh += @{ file = $file; trust = $trust } }
            "AGING" { $aging += @{ file = $file; trust = $trust } }
            "STALE" { $stale += @{ file = $file; trust = $trust } }
        }
    }
}

# Display categories
if ($fresh.Count -gt 0) {
    Write-Host "FRESH " -ForegroundColor Green -NoNewline
    Write-Host "(high confidence - use directly)" -ForegroundColor Gray
    foreach ($item in $fresh) {
        Format-FileEntry $item.file $item.trust $Detail
    }
    Write-Host ""
}

if ($aging.Count -gt 0) {
    Write-Host "AGING " -ForegroundColor Yellow -NoNewline
    Write-Host "(medium confidence - validate if critical)" -ForegroundColor Gray
    foreach ($item in $aging) {
        Format-FileEntry $item.file $item.trust $Detail
    }
    Write-Host ""
}

if ($stale.Count -gt 0) {
    Write-Host "STALE " -ForegroundColor Red -NoNewline
    Write-Host "(low confidence - verify before acting)" -ForegroundColor Gray
    foreach ($item in $stale) {
        Format-FileEntry $item.file $item.trust $Detail
    }
    Write-Host ""
}

if ($honored.Count -gt 0) {
    Write-Host "HONORED " -ForegroundColor Cyan -NoNewline
    Write-Host "(stable foundation - historical lessons)" -ForegroundColor Gray
    foreach ($item in $honored) {
        Format-FileEntry $item.file $item.trust $Detail
    }
    Write-Host ""
}

# Overall assessment
Write-Host ("=" * 70) -ForegroundColor DarkGray

$totalFiles = $fresh.Count + $aging.Count + $stale.Count
$overallConfidence = if ($stale.Count -gt $totalFiles/2) {
    @{ level = "LOW"; color = "Red" }
} elseif ($fresh.Count -gt $totalFiles/2) {
    @{ level = "HIGH"; color = "Green" }
} else {
    @{ level = "MEDIUM"; color = "Yellow" }
}

Write-Host "Files: $totalFiles total " -NoNewline -ForegroundColor Cyan
Write-Host "($($fresh.Count) fresh, $($aging.Count) aging, $($stale.Count) stale)" -ForegroundColor Gray

if ($honored.Count -gt 0) {
    Write-Host "Honored: $($honored.Count) files in stable archive" -ForegroundColor Cyan
}

Write-Host "Overall confidence: " -NoNewline -ForegroundColor Cyan
Write-Host $overallConfidence.level -ForegroundColor $overallConfidence.color
Write-Host ""

# Recommendations
if ($stale.Count -gt 0) {
    Write-Host "RECOMMENDATIONS:" -ForegroundColor Yellow
    Write-Host "  • Review stale files before making decisions based on them" -ForegroundColor Gray
    Write-Host "  • Update files that are still active, or" -ForegroundColor Gray
    Write-Host "  • Run: ./ctx forgive all --reason 'describe what happened'" -ForegroundColor Gray

    if ($stale.Count -gt 3) {
        Write-Host ""
        Write-Host "  Large drift detected. Consider:" -ForegroundColor Yellow
        Write-Host "    1. What's still relevant? Update those files" -ForegroundColor Gray
        Write-Host "    2. What was learned? Run: ./ctx honor <file> --lesson '...'" -ForegroundColor Gray
        Write-Host "    3. Acknowledge the gap: ./ctx forgive all" -ForegroundColor Gray
    }
}

if ($Detail) {
    Write-Host ""
    Write-Host "TRUST LEVELS EXPLAINED:" -ForegroundColor Yellow
    Write-Host "  FRESH (0-$FRESH_DAYS days): " -NoNewline -ForegroundColor Green
    Write-Host "Quote directly, assume accurate" -ForegroundColor Gray

    Write-Host "  AGING ($FRESH_DAYS-$AGING_DAYS days): " -NoNewline -ForegroundColor Yellow
    Write-Host "Use cautiously, note age when referencing" -ForegroundColor Gray

    Write-Host "  STALE (${AGING_DAYS}+ days): " -NoNewline -ForegroundColor Red
    Write-Host "Treat as historical, verify before acting" -ForegroundColor Gray

    Write-Host "  HONORED (archived): " -NoNewline -ForegroundColor Cyan
    Write-Host "Extracted lessons, stable reference" -ForegroundColor Gray
}

Write-Host ""
exit 0
