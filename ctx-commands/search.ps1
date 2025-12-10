#!/usr/bin/env pwsh
# ctx search - Wedge-style term search across context files
# Usage: ./ctx search <term> [--depth N] [--expand] [--case]
#
# Returns matches with surrounding context and expansion hints

param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$SearchTerm,

    [Parameter(Position=1)]
    [string]$Path,

    [Parameter()]
    [int]$Depth = 2,

    [Parameter()]
    [switch]$Expand,

    [Parameter()]
    [switch]$Case,

    [Parameter()]
    [switch]$Full
)

$ScriptRoot = Split-Path -Parent $PSScriptRoot
$ContextDir = if ($Path) { $Path } else { Join-Path $ScriptRoot ".context" }

if (-not (Test-Path $ContextDir)) {
    Write-Host "NO CONTEXT DIRECTORY FOUND" -ForegroundColor Yellow
    Write-Host "Expected: $ContextDir" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Specify a path with: ./ctx search term /path/to/.context" -ForegroundColor Gray
    exit 1
}

# Validate depth parameter
if ($Depth -lt 0 -or $Depth -gt 10) {
    Write-Host "ERROR: --depth must be between 0 and 10" -ForegroundColor Red
    exit 1
}

# Build Select-String parameters
$selectStringParams = @{
    Path = Get-ChildItem -Path $ContextDir -Recurse -File -Include "*.md","*.json" | Select-Object -ExpandProperty FullName
    Pattern = $SearchTerm
    Context = $Depth, $Depth
}

if (-not $Case) {
    $selectStringParams['CaseSensitive'] = $false
} else {
    $selectStringParams['CaseSensitive'] = $true
}

Write-Host ""
Write-Host "SEARCH: `"$SearchTerm`" in $ContextDir" -ForegroundColor Cyan
Write-Host ""

# Perform search
try {
    $matches = Select-String @selectStringParams -ErrorAction Stop
} catch {
    Write-Host "No matches found." -ForegroundColor Gray
    exit 1
}

if (-not $matches) {
    Write-Host "No matches found." -ForegroundColor Gray
    exit 1
}

# Group matches by file for better presentation
$groupedMatches = $matches | Group-Object Path

$totalMatches = 0
$fileCount = $groupedMatches.Count
$nearbyTerms = @()

foreach ($fileGroup in $groupedMatches) {
    $relativePath = $fileGroup.Name.Replace($ContextDir, "").TrimStart('\', '/')
    $fileMatches = $fileGroup.Group
    $matchCount = $fileMatches.Count
    $totalMatches += $matchCount

    # Show first 3 matches unless --full specified
    $displayMatches = if ($Full) { $fileMatches } else { $fileMatches | Select-Object -First 3 }

    foreach ($match in $displayMatches) {
        Write-Host "$relativePath`:$($match.LineNumber)" -ForegroundColor Yellow

        # Show context before
        if ($match.Context.PreContext) {
            foreach ($line in $match.Context.PreContext) {
                $lineNum = $match.LineNumber - ($match.Context.PreContext.Length - $match.Context.PreContext.IndexOf($line))
                Write-Host ("  {0,3}| {1}" -f $lineNum, $line) -ForegroundColor DarkGray
            }
        }

        # Show the matching line with highlight
        Write-Host ("> {0,3}| {1}" -f $match.LineNumber, $match.Line) -ForegroundColor White

        # Show context after
        if ($match.Context.PostContext) {
            $postLineNum = $match.LineNumber + 1
            foreach ($line in $match.Context.PostContext) {
                Write-Host ("  {0,3}| {1}" -f $postLineNum, $line) -ForegroundColor DarkGray
                $postLineNum++
            }
        }

        Write-Host ""

        # Extract nearby terms for expansion (if --expand)
        if ($Expand) {
            $contextText = ($match.Context.PreContext + $match.Line + $match.Context.PostContext) -join " "
            # Extract word-like identifiers (camelCase, PascalCase, snake_case, kebab-case)
            $words = [regex]::Matches($contextText, '\b[A-Za-z][A-Za-z0-9_-]*\b') |
                     Select-Object -ExpandProperty Value |
                     Where-Object { $_.Length -gt 3 -and $_ -ne $SearchTerm }
            $nearbyTerms += $words
        }
    }

    # If more matches exist, show count
    if (-not $Full -and $matchCount -gt 3) {
        Write-Host "  ... and $($matchCount - 3) more matches in this file" -ForegroundColor DarkGray
        Write-Host ""
    }
}

Write-Host ("=" * 70) -ForegroundColor DarkGray
Write-Host "Found $totalMatches matches in $fileCount files." -ForegroundColor Cyan

# Show nearby terms if --expand
if ($Expand -and $nearbyTerms.Count -gt 0) {
    $uniqueTerms = $nearbyTerms |
                   Group-Object |
                   Sort-Object Count -Descending |
                   Select-Object -First 8 -ExpandProperty Name
    Write-Host "Nearby terms: [$($uniqueTerms -join ', ')]" -ForegroundColor Gray
}

Write-Host ""
exit 0
