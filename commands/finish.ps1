#!/usr/bin/env pwsh
# ctx finish - Complete iteration and prepare for handoff

param(
    [Parameter(Position=0)]
    [string]$Action = "default",
    
    [switch]$Archive,
    [Alias("continue-mission")]
    [switch]$ContinueMission,
    [string]$Summary,
    [switch]$Help,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

# Load shared config library
. (Join-Path $PSScriptRoot ".." "lib" "config.ps1")

# Get context path using shared function
$contextPath = Get-CtxContextPath
$config = Get-CtxConfig
$projectName = $config.current_project
$gitRoot = $config.projects.$projectName.git_root

# Augmented header
if (-not $Quiet) {
    $relativeCtx = $contextPath -replace [regex]::Escape($gitRoot), "[git]"
    Write-Host "[git:$gitRoot ctx:$relativeCtx cmd:finish:exists]" -ForegroundColor DarkGray
    Write-Host ""
}

# File paths
$stateFile = Join-Path $contextPath "state.md"
$historyFile = Join-Path $contextPath "history.md"
$stateJson = Join-Path $contextPath "state.json"

# Show help
if ($Help -or $Action -eq "help") {
    Write-Host "ctx finish - Complete iteration and prepare for handoff" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  ctx finish                  Complete iteration, archive, mark mission done"
    Write-Host "  ctx finish --continue-mission  Complete iteration, prepare for next"
    Write-Host "  ctx finish --archive        Force archive to handoffs/"
    Write-Host "  ctx finish --summary <text> Override auto-detected summary"
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Yellow
    Write-Host "  --archive            Archive context to handoffs/YYYY-MM-DD-HHMM/"
    Write-Host "  --continue-mission   Keep mission active, prepare Next section"
    Write-Host "  --summary <text>     Custom summary (otherwise auto-detected from state.md)"
    Write-Host "  --quiet              Suppress header output"
    Write-Host ""
    Write-Host "Behavior:" -ForegroundColor Yellow
    Write-Host "  Default (mission complete):"
    Write-Host "    1. Summarize iteration work"
    Write-Host "    2. Update history.md with completed iteration"
    Write-Host "    3. Archive to handoffs/"
    Write-Host "    4. Mark mission complete in state.md"
    Write-Host ""
    Write-Host "  With --continue-mission:"
    Write-Host "    1. Summarize iteration work"
    Write-Host "    2. Update history.md"
    Write-Host "    3. Update state.md Next section for next iteration"
    Write-Host "    4. NO archive - mission continues"
    Write-Host ""
    exit 0
}

# Parse state.md for iteration info
function Get-IterationInfo {
    if (-not (Test-Path $stateFile)) {
        return @{
            iteration = 1
            phase = "Unknown"
            startTime = $null
            activeWork = @()
            nextWork = @()
        }
    }
    
    $state = Get-Content $stateFile -Raw
    
    # Extract iteration number from history - find max iteration and increment
    $iteration = 1
    if (Test-Path $historyFile) {
        $history = Get-Content $historyFile -Raw
        $iterMatches = [regex]::Matches($history, '\*\*Iteration:\*\*\s*(\d+)')
        if ($iterMatches.Count -gt 0) {
            # Find maximum iteration number
            $maxIter = ($iterMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
            $iteration = $maxIter + 1
        }
    }
    
    # Extract phase
    $phase = "Unknown"
    if ($state -match '\*\*Phase:\*\*\s*(.+)') {
        $phase = $matches[1].Trim()
    }
    
    # Extract active work (Now section)
    $activeWork = @()
    if ($state -match '(?s)### Now\s*(.+?)(?=\n### |## |$)') {
        $nowSection = $matches[1].Trim()
        $activeWork = [regex]::Matches($nowSection, '(?m)^[\s]*-\s*(.+)$') | 
            ForEach-Object { $_.Groups[1].Value.Trim() }
    }
    
    # Extract next work
    $nextWork = @()
    if ($state -match '(?s)### Next\s*(.+?)(?=\n## |$)') {
        $nextSection = $matches[1].Trim()
        $nextWork = [regex]::Matches($nextSection, '(?m)^[\s]*\d+\.\s*(.+)$') |
            ForEach-Object { $_.Groups[1].Value.Trim() }
    }
    
    # Extract updated date as proxy for start time
    $startTime = Get-Date
    if ($state -match '\*\*Updated:\*\*\s*(\d{4}-\d{2}-\d{2})') {
        $startTime = [DateTime]::Parse($matches[1])
    }
    
    return @{
        iteration = $iteration
        phase = $phase
        startTime = $startTime
        activeWork = $activeWork
        nextWork = $nextWork
    }
}

# Generate summary from completed work
function Get-CompletedSummary {
    param([hashtable]$Info)
    
    $completed = @()
    
    # Use active work items as completed
    foreach ($item in $Info.activeWork) {
        if ($item -and $item.Length -gt 0) {
            $completed += $item
        }
    }
    
    # Check state.json for completed work items
    if (Test-Path $stateJson) {
        $stateData = Get-Content $stateJson -Raw | ConvertFrom-Json
        $completedItems = $stateData.work_items | Where-Object { $_.status -eq "completed" }
        foreach ($item in $completedItems) {
            $completed += $item.title
        }
    }
    
    if ($completed.Count -eq 0) {
        $completed += "Iteration work completed"
    }
    
    return $completed
}

# Update history.md with completed iteration
function Update-History {
    param(
        [hashtable]$Info,
        [string[]]$Completed,
        [string]$MissionStatus
    )
    
    $date = Get-Date -Format 'yyyy-MM-dd'
    $time = Get-Date -Format 'HH:mm'
    
    # Build new history entry
    $entry = @"

### $date $time - Iteration $($Info.iteration) Complete
**Iteration:** $($Info.iteration)
**Phase:** $($Info.phase)

**Completed:**
$(($Completed | ForEach-Object { "- $_" }) -join "`n")

**Mission Status:** $MissionStatus

---

"@
    
    if (Test-Path $historyFile) {
        $history = Get-Content $historyFile -Raw
        
        # Insert after the timeline header
        if ($history -match '(## Timeline \(Reverse Chronological\))') {
            $insertPoint = $history.IndexOf($matches[1]) + $matches[1].Length
            $newHistory = $history.Substring(0, $insertPoint) + "`n" + $entry + $history.Substring($insertPoint)
            $newHistory | Set-Content $historyFile
        } else {
            # Append to end if no timeline section
            $history + $entry | Set-Content $historyFile
        }
    } else {
        # Create new history file
        $newHistory = @"
# Project History

**Project:** $projectName
**Started:** $date

## Timeline (Reverse Chronological)
$entry
---

*This file tracks: WHAT happened WHEN*
*See: state.md for current work, decisions.md for why*
"@
        $newHistory | Set-Content $historyFile
    }
}

# Archive to handoffs directory
function Invoke-Archive {
    $timestamp = Get-Date -Format 'yyyy-MM-dd-HHmm'
    $handoffsDir = Join-Path $contextPath "handoffs"
    $archiveDir = Join-Path $handoffsDir $timestamp
    
    if (-not (Test-Path $handoffsDir)) {
        New-Item -ItemType Directory -Path $handoffsDir -Force | Out-Null
    }
    
    New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    
    # Copy all context files
    $filesToCopy = @("state.md", "state.json", "history.md", "decisions.md", "decisions.json", 
                     "codebase.md", "TODOS.md", "guide.md", "fear.md")
    
    foreach ($file in $filesToCopy) {
        $sourcePath = Join-Path $contextPath $file
        if (Test-Path $sourcePath) {
            Copy-Item $sourcePath $archiveDir
        }
    }
    
    return $archiveDir
}

# Update state.md for next iteration
function Update-StateForNext {
    param([string[]]$NextFocus)
    
    if (-not (Test-Path $stateFile)) { return }
    
    $state = Get-Content $stateFile -Raw
    $date = Get-Date -Format 'yyyy-MM-dd'
    
    # Update the Updated date
    $state = $state -replace '\*\*Updated:\*\*\s*\d{4}-\d{2}-\d{2}', "**Updated:** $date"
    
    # Move Next to Now, clear Next
    if ($state -match '(?s)(### Now\s*)(.+?)(### Next)') {
        $nextContent = if ($NextFocus.Count -gt 0) {
            ($NextFocus | ForEach-Object { "- $_" }) -join "`n"
        } else {
            "- Continue mission objectives"
        }
        
        $newNow = "### Now`n$nextContent`n`n"
        $newNext = "### Next`n1. Define next iteration goals`n2. Review and prioritize`n"
        
        $state = $state -replace '(?s)### Now\s*.+?### Next\s*.+?(?=\n## |$)', "$newNow$newNext`n"
    }
    
    $state | Set-Content $stateFile
}

# Mark mission complete in state.md
function Update-StateComplete {
    if (-not (Test-Path $stateFile)) { return }
    
    $state = Get-Content $stateFile -Raw
    $date = Get-Date -Format 'yyyy-MM-dd'
    
    # Update the Updated date
    $state = $state -replace '\*\*Updated:\*\*\s*\d{4}-\d{2}-\d{2}', "**Updated:** $date"
    
    # Update phase to Complete
    $state = $state -replace '\*\*Phase:\*\*\s*.+', "**Phase:** Complete"
    
    # Clear Now section
    $state = $state -replace '(?s)(### Now\s*).+?(### Next|## )', "`$1- Mission completed`n`n`$2"
    
    $state | Set-Content $stateFile
}

# Main execution
$info = Get-IterationInfo

# Get completed items
$completed = if ($Summary) { @($Summary) } else { Get-CompletedSummary -Info $info }

# Determine mission status
$missionStatus = if ($ContinueMission) { "CONTINUING" } else { "COMPLETE" }

# Display iteration completion
Write-Host "ITERATION COMPLETE" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan
Write-Host ""

$endTime = Get-Date
$duration = if ($info.startTime) {
    "ctx start ($($info.startTime.ToString('yyyy-MM-dd'))) → ctx finish ($($endTime.ToString('yyyy-MM-dd HH:mm')))"
} else {
    "Completed: $($endTime.ToString('yyyy-MM-dd HH:mm'))"
}

Write-Host "Duration: $duration" -ForegroundColor White
Write-Host "Iteration: $($info.iteration)" -ForegroundColor White
Write-Host ""

Write-Host "Completed:" -ForegroundColor Yellow
foreach ($item in $completed) {
    Write-Host "  ✓ $item" -ForegroundColor Green
}
Write-Host ""

Write-Host "Mission Status: $missionStatus" -ForegroundColor $(if ($ContinueMission) { "Yellow" } else { "Green" })

if ($ContinueMission -and $info.nextWork.Count -gt 0) {
    Write-Host "Next Iteration Focus: $($info.nextWork[0])" -ForegroundColor White
}
Write-Host ""

# Update history
Update-History -Info $info -Completed $completed -MissionStatus $missionStatus
Write-Host "History updated: $historyFile" -ForegroundColor Gray

# Archive if requested or default (mission complete)
$archivePath = $null
if ($Archive -or (-not $ContinueMission)) {
    $archivePath = Invoke-Archive
    Write-Host "Archived: $archivePath" -ForegroundColor Gray
} else {
    Write-Host "Archived: No (--continue-mission)" -ForegroundColor Gray
}

# Update state
if ($ContinueMission) {
    Update-StateForNext -NextFocus $info.nextWork
    Write-Host "State prepared for next iteration" -ForegroundColor Gray
} else {
    Update-StateComplete
    Write-Host "Mission marked complete" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Iteration $($info.iteration) finished ===" -ForegroundColor Green
