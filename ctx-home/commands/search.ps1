#!/usr/bin/env pwsh
# search.ps1 - Wedge-style term search across context files
# Usage: search.ps1 <term> [--depth N] [--expand] [--case]

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$SearchTerm,
    
    [Parameter()]
    [int]$Depth = 2,
    
    [Parameter()]
    [switch]$Expand,
    
    [Parameter()]
    [switch]$Case,
    
    [Parameter()]
    [switch]$Full
)

$ErrorActionPreference = 'Stop'

# Load implicit labeling
. (Join-Path $PSScriptRoot ".." "lib" "labeling.ps1")

# Use resolved context directory from environment if available
$DefaultContextDir = if ($env:CTX_CONTEXT_DIR) {
    $env:CTX_CONTEXT_DIR
} else {
    # Legacy fallback: Navigate from ctx-commands/ -> ctx/ -> scripts/ -> project root
    $ScriptDir = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    Join-Path $ScriptDir ".ctx"
}

$ContextDir = $DefaultContextDir

if (-not (Test-Path $ContextDir)) {
    Write-Host "No context directory found at: $ContextDir" -ForegroundColor Red
    Write-Host "Create project context first or run inside a registered project." -ForegroundColor Gray
    exit 1
}

# Validate depth
if ($Depth -lt 0) { $Depth = 0 }
if ($Depth -gt 10) { $Depth = 10 }

# Search for matches
$caseSensitive = $Case.IsPresent
$matchType = if ($caseSensitive) { "CaseSensitive" } else { "SimpleMatch" }

Write-Host "SEARCH: ""$SearchTerm"" in context" -ForegroundColor Cyan
Write-Host ""

$allMatches = @()
$filesSearched = 0
$filesWithMatches = 0

Get-ChildItem -Path $ContextDir -File -Recurse | ForEach-Object {
    $file = $_
    $filesSearched++
    
    # Skip binary files
    if ($file.Extension -in @('.exe', '.dll', '.bin', '.obj', '.zip', '.png', '.jpg', '.gif')) {
        return
    }
    
    try {
        $matches = Select-String -Path $file.FullName -Pattern $SearchTerm -Context $Depth,$Depth -CaseSensitive:$caseSensitive
        
        if ($matches) {
            $filesWithMatches++
            foreach ($match in $matches) {
                $allMatches += [PSCustomObject]@{
                    File = $file.Name
                    RelativePath = $file.FullName.Replace("$ContextDir\", "")
                    LineNumber = $match.LineNumber
                    Line = $match.Line
                    Context = $match.Context
                    Match = $match
                }
            }
        }
    } catch {
        # Skip files that can't be read as text
    }
}

if ($allMatches.Count -eq 0) {
    Write-Host "No matches found." -ForegroundColor Yellow
    exit 1
}

# Display results
$displayCount = 0
$maxDisplay = if ($Full) { [int]::MaxValue } else { 50 }

$groupedByFile = $allMatches | Group-Object -Property RelativePath

foreach ($fileGroup in $groupedByFile) {
    $fileMatches = $fileGroup.Group
    $displayMatches = if ($fileMatches.Count -gt 3 -and -not $Full) { 
        $fileMatches | Select-Object -First 3 
    } else { 
        $fileMatches 
    }
    
    foreach ($match in $displayMatches) {
        if ($displayCount -ge $maxDisplay) { break }
        
        Write-Host "$($match.RelativePath):$($match.LineNumber)" -ForegroundColor Green
        
        # Show context before
        $contextBefore = $match.Context.PreContext
        if ($contextBefore) {
            $startLine = $match.LineNumber - $contextBefore.Count
            for ($i = 0; $i -lt $contextBefore.Count; $i++) {
                $lineNum = $startLine + $i
                $contextLine = $contextBefore[$i]
                if ($contextLine.Length -gt 120) {
                    $contextLine = $contextLine.Substring(0, 117) + "..."
                }
                Write-Host "  $($lineNum.ToString().PadLeft(3))│ $contextLine" -ForegroundColor Gray
            }
        }
        
        # Show matched line
        $matchedLine = $match.Line
        if ($matchedLine.Length -gt 120) {
            $matchedLine = $matchedLine.Substring(0, 117) + "..."
        }
        Write-Host "> $($match.LineNumber.ToString().PadLeft(3))│ $matchedLine" -ForegroundColor White
        
        # Show context after
        $contextAfter = $match.Context.PostContext
        if ($contextAfter) {
            $startLine = $match.LineNumber + 1
            for ($i = 0; $i -lt $contextAfter.Count; $i++) {
                $lineNum = $startLine + $i
                $contextLine = $contextAfter[$i]
                if ($contextLine.Length -gt 120) {
                    $contextLine = $contextLine.Substring(0, 117) + "..."
                }
                Write-Host "  $($lineNum.ToString().PadLeft(3))│ $contextLine" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        $displayCount++
    }
    
    # Note if there are more matches in this file
    if ($fileMatches.Count -gt 3 -and -not $Full) {
        $remaining = $fileMatches.Count - 3
        Write-Host "  ... and $remaining more in this file" -ForegroundColor DarkGray
        Write-Host ""
    }
    
    if ($displayCount -ge $maxDisplay) { break }
}

# Summary
Write-Host "Found $($allMatches.Count) matches in $filesWithMatches files." -ForegroundColor Cyan
`n# Expand: find nearby terms
if ($Expand) {
    Write-Host ""
    $nearbyTerms = @{}
    
    foreach ($match in $allMatches) {
        # Extract words from context lines
        $allContextText = (@($match.Context.PreContext) + @($match.Line) + @($match.Context.PostContext)) -join " "
        
        # Find potential identifiers (camelCase, PascalCase, snake_case, etc.)
        $words = [regex]::Matches($allContextText, '\b[A-Z][a-z]+(?:[A-Z][a-z]+)*\b|\b[a-z]+(?:_[a-z]+)+\b|\b[A-Z_]+\b') | 
                 ForEach-Object { $_.Value } |
                 Where-Object { $_ -ne $SearchTerm -and $_.Length -gt 2 }
        
        foreach ($word in $words) {
            if (-not $nearbyTerms.ContainsKey($word)) {
                $nearbyTerms[$word] = 0
            }
            $nearbyTerms[$word]++
        }
    }
    
    if ($nearbyTerms.Count -gt 0) {
        $topTerms = $nearbyTerms.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 -ExpandProperty Key
        Write-Host "Nearby terms: [$($topTerms -join ', ')]" -ForegroundColor DarkCyan
    }
}

exit 0

