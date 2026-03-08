#!/usr/bin/env pwsh
# ctx decision - CRUD for architectural decisions

param(
    [Parameter(Position=0)]
    [string]$Action = "show",
    
    [Parameter(Position=1)]
    [string]$Arg1,
    
    [string]$Id,
    [string]$Title,
    [string]$Decision,
    [string]$Context,
    [string]$Rationale,
    [string[]]$Tag,
    [ValidateSet("accepted", "proposed", "deprecated", "rejected", "deferred")]
    [string]$Status,
    [ValidateSet("high", "medium", "low")]
    [string]$Confidence,
    [switch]$List,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

# Load shared config library
. (Join-Path $PSScriptRoot ".." "lib" "config.ps1")

# Get context path using shared function
$contextPath = Get-CtxContextPath
$config = Get-CtxConfig
$gitRoot = $config.projects.($config.current_project).git_root

# Augmented header
if (-not $Quiet) {
    $relativeCtx = $contextPath -replace [regex]::Escape($gitRoot), "[git]"
    Write-Host "[git:$gitRoot ctx:$relativeCtx cmd:decision:exists]" -ForegroundColor DarkGray
    Write-Host ""
}

# File paths
$decisionsJson = Join-Path $contextPath "decisions.json"
$decisionsMd = Join-Path $contextPath "decisions.md"

# Initialize decisions.json if needed
function Initialize-Decisions {
    if (-not (Test-Path $decisionsJson)) {
        $initial = @{
            version = "1.0"
            decisions = @()
        }
        $initial | ConvertTo-Json -Depth 10 | Set-Content $decisionsJson
    }
}

# Load decisions
function Get-DecisionsData {
    Initialize-Decisions
    return Get-Content $decisionsJson -Raw | ConvertFrom-Json
}

# Save decisions and regenerate MD
function Save-DecisionsData {
    param($Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content $decisionsJson
    Update-DecisionsMd $Data
}

# Update MD file
function Update-DecisionsMd {
    param($Data)
    
    $mdContent = @"
# Architectural Decisions

**Project:** Stwoart (StartMenu -> Start Migration)
**Updated:** $(Get-Date -Format 'yyyy-MM-dd')
**Source:** decisions.json (this file is auto-generated)

"@

    foreach ($d in $Data.decisions) {
        $mdContent += "`n## $($d.title)`n"
        $mdContent += "**ID:** $($d.id) | **Status:** $($d.status) | **Confidence:** $($d.confidence)`n"
        $mdContent += "**Date:** $($d.date) | **Tags:** $($d.tags -join ', ')`n`n"
        $mdContent += "**Context:** $($d.ctx)`n`n"
        $mdContent += "**Decision:** $($d.decision)`n`n"
        
        if ($d.design) {
            $mdContent += "**Design:** $($d.design)`n`n"
        }
        
        if ($d.alternatives -and $d.alternatives.Count -gt 0) {
            $mdContent += "**Alternatives:**`n"
            foreach ($alt in $d.alternatives) {
                $mdContent += "- $alt`n"
            }
            $mdContent += "`n"
        }
        
        $mdContent += "**Rationale:** $($d.rationale)`n`n"
        
        if ($d.related -and $d.related.Count -gt 0) {
            $mdContent += "**Related:** $($d.related -join ', ')`n`n"
        }
    }

    $mdContent += "`n---`n`n*This file tracks: WHY things are this way*`n"
    $mdContent += "*Auto-generated from decisions.json - use 'ctx decision' commands to query*`n"

    $mdContent | Set-Content $decisionsMd
}

# Show decisions (with filtering)
function Show-Decisions {
    param([string]$Query, [switch]$ListAll)
    
    $data = Get-DecisionsData
    $filtered = $data.decisions
    
    if ($Tag) {
        $filtered = $filtered | Where-Object {
            $decisionTags = $_.tags
            $Tag | ForEach-Object { $tagToFind = $_; $decisionTags -contains $tagToFind } | Where-Object { $_ } | Select-Object -First 1
        }
    }
    
    if ($Status) {
        $filtered = $filtered | Where-Object { $_.status -eq $Status }
    }
    
    if ($Confidence) {
        $filtered = $filtered | Where-Object { $_.confidence -eq $Confidence }
    }
    
    if ($Query) {
        $filtered = $filtered | Where-Object { 
            $_.id -like "*$Query*" -or $_.title -like "*$Query*"
        }
    }
    
    if ($ListAll -or $List) {
        Write-Host "=== DECISIONS ===" -ForegroundColor Cyan
        Write-Host "Total: $($data.decisions.Count) | Filtered: $($filtered.Count)" -ForegroundColor Gray
        Write-Host ""
        
        foreach ($d in $filtered) {
            $statusColor = switch ($d.status) {
                "accepted" { "Green" }
                "proposed" { "Yellow" }
                "deprecated" { "DarkGray" }
                "rejected" { "Red" }
                default { "White" }
            }
            
            Write-Host "[$($d.id)]" -ForegroundColor Cyan -NoNewline
            Write-Host " $($d.title)" -ForegroundColor White
            Write-Host "  Status: " -NoNewline -ForegroundColor Gray
            Write-Host $d.status -ForegroundColor $statusColor -NoNewline
            Write-Host " | Confidence: $($d.confidence)" -ForegroundColor Gray
            Write-Host "  Tags: $($d.tags -join ', ')" -ForegroundColor DarkGray
            Write-Host ""
        }
    } elseif ($filtered.Count -eq 0) {
        Write-Host "No decisions match filters." -ForegroundColor Yellow
    } elseif ($filtered.Count -eq 1) {
        Show-DecisionDetail $filtered[0]
    } else {
        Write-Host "=== DECISIONS (Filtered: $($filtered.Count)) ===" -ForegroundColor Cyan
        Write-Host ""
        
        foreach ($d in $filtered) {
            Write-Host "[$($d.id)]" -ForegroundColor Cyan -NoNewline
            Write-Host " $($d.title)" -ForegroundColor White
            Write-Host "  $($d.decision)" -ForegroundColor Gray
            Write-Host ""
        }
        
        Write-Host "Use 'ctx decision <id>' for full details" -ForegroundColor DarkGray
    }
}

# Show single decision detail
function Show-DecisionDetail {
    param($d)
    
    Write-Host "=== $($d.title) ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "ID: " -NoNewline -ForegroundColor Gray
    Write-Host $d.id -ForegroundColor White
    Write-Host "Date: " -NoNewline -ForegroundColor Gray
    Write-Host $d.date -ForegroundColor White
    Write-Host "Status: " -NoNewline -ForegroundColor Gray
    Write-Host $d.status -ForegroundColor Green
    Write-Host "Confidence: " -NoNewline -ForegroundColor Gray
    Write-Host $d.confidence -ForegroundColor White
    Write-Host "Tags: " -NoNewline -ForegroundColor Gray
    Write-Host ($d.tags -join ', ') -ForegroundColor DarkCyan
    Write-Host ""
    
    Write-Host "Context:" -ForegroundColor Yellow
    Write-Host $d.ctx
    Write-Host ""
    
    Write-Host "Decision:" -ForegroundColor Yellow
    Write-Host $d.decision
    Write-Host ""
    
    if ($d.design) {
        Write-Host "Design:" -ForegroundColor Yellow
        Write-Host $d.design
        Write-Host ""
    }
    
    if ($d.alternatives -and $d.alternatives.Count -gt 0) {
        Write-Host "Alternatives Considered:" -ForegroundColor Yellow
        foreach ($alt in $d.alternatives) {
            Write-Host "  - $alt" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    Write-Host "Rationale:" -ForegroundColor Yellow
    Write-Host $d.rationale
    Write-Host ""
    
    Write-Host "Consequences:" -ForegroundColor Yellow
    if ($d.consequences.positive) {
        Write-Host "  Positive:" -ForegroundColor Green
        foreach ($p in $d.consequences.positive) {
            Write-Host "    + $p" -ForegroundColor Gray
        }
    }
    if ($d.consequences.negative) {
        Write-Host "  Negative:" -ForegroundColor Red
        foreach ($n in $d.consequences.negative) {
            Write-Host "    - $n" -ForegroundColor Gray
        }
    }
    Write-Host ""
    
    if ($d.related -and $d.related.Count -gt 0) {
        Write-Host "Related: " -NoNewline -ForegroundColor Gray
        Write-Host ($d.related -join ', ') -ForegroundColor DarkCyan
        Write-Host ""
    }
}

# Add a new decision
function Add-Decision {
    param(
        [string]$DecisionId,
        [string]$DecisionTitle,
        [string]$DecisionText,
        [string]$DecisionContext,
        [string]$DecisionRationale,
        [string]$DecisionStatus,
        [string]$DecisionConfidence,
        [string[]]$DecisionTags
    )
    
    if (-not $DecisionId -or -not $DecisionTitle) {
        Write-Error "Required: --id and --title"
        return
    }
    
    $data = Get-DecisionsData
    
    # Check for duplicate ID
    if ($data.decisions | Where-Object { $_.id -eq $DecisionId }) {
        Write-Error "Decision ID '$DecisionId' already exists"
        return
    }
    
    $newDecision = [ordered]@{
        id = $DecisionId
        title = $DecisionTitle
        date = (Get-Date -Format 'yyyy-MM-dd')
        status = if ($DecisionStatus) { $DecisionStatus } else { "proposed" }
        confidence = if ($DecisionConfidence) { $DecisionConfidence } else { "medium" }
        tags = if ($DecisionTags) { $DecisionTags } else { @() }
        context = if ($DecisionContext) { $DecisionContext } else { "" }
        decision = if ($DecisionText) { $DecisionText } else { "" }
        rationale = if ($DecisionRationale) { $DecisionRationale } else { "" }
        alternatives = @()
        consequences = @{
            positive = @()
            negative = @()
        }
        related = @()
    }
    
    $data.decisions += $newDecision
    Save-DecisionsData $data
    Write-Host "Added decision [$DecisionId]: $DecisionTitle" -ForegroundColor Green
}

# Update an existing decision
function Update-Decision {
    param(
        [string]$DecisionId,
        [string]$NewTitle,
        [string]$NewDecision,
        [string]$NewContext,
        [string]$NewRationale,
        [string]$NewStatus,
        [string]$NewConfidence,
        [string[]]$NewTags
    )
    
    $data = Get-DecisionsData
    $d = $data.decisions | Where-Object { $_.id -eq $DecisionId }
    
    if (-not $d) {
        Write-Error "Decision ID '$DecisionId' not found"
        return
    }
    
    $changes = @()
    
    if ($NewTitle) { $d.title = $NewTitle; $changes += "title" }
    if ($NewDecision) { $d.decision = $NewDecision; $changes += "decision" }
    if ($NewContext) { $d.ctx = $NewContext; $changes += "context" }
    if ($NewRationale) { $d.rationale = $NewRationale; $changes += "rationale" }
    if ($NewStatus) { $d.status = $NewStatus; $changes += "status" }
    if ($NewConfidence) { $d.confidence = $NewConfidence; $changes += "confidence" }
    if ($NewTags) { $d.tags = $NewTags; $changes += "tags" }
    
    if ($changes.Count -eq 0) {
        Write-Host "No changes specified." -ForegroundColor Yellow
        return
    }
    
    Save-DecisionsData $data
    Write-Host "[$DecisionId] updated: $($changes -join ', ')" -ForegroundColor Green
}

# Remove a decision
function Remove-Decision {
    param([string]$DecisionId)
    
    $data = Get-DecisionsData
    $before = $data.decisions.Count
    $data.decisions = @($data.decisions | Where-Object { $_.id -ne $DecisionId })
    
    if ($data.decisions.Count -eq $before) {
        Write-Error "Decision ID '$DecisionId' not found"
        return
    }
    
    Save-DecisionsData $data
    Write-Host "Removed decision [$DecisionId]" -ForegroundColor Yellow
}

# Main command router
switch ($Action.ToLower()) {
    "show" {
        Show-Decisions -Query $Arg1
    }
    "list" {
        Show-Decisions -Query $Arg1 -ListAll
    }
    "add" {
        Add-Decision -DecisionId $Id -DecisionTitle $Title -DecisionText $Decision `
            -DecisionContext $Context -DecisionRationale $Rationale `
            -DecisionStatus $Status -DecisionConfidence $Confidence -DecisionTags $Tag
    }
    "update" {
        if (-not $Arg1 -and -not $Id) {
            Write-Error "Usage: ctx decision update <id> [--title, --decision, --context, --rationale, --status, --confidence, --tag]"
            exit 1
        }
        $targetId = if ($Arg1) { $Arg1 } else { $Id }
        Update-Decision -DecisionId $targetId -NewTitle $Title -NewDecision $Decision `
            -NewContext $Context -NewRationale $Rationale `
            -NewStatus $Status -NewConfidence $Confidence -NewTags $Tag
    }
    "remove" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx decision remove <id>"
            exit 1
        }
        Remove-Decision -DecisionId $Arg1
    }
    "help" {
        Write-Host "ctx decision - CRUD for architectural decisions" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  show [query]           Search/show decisions (default)"
        Write-Host "  list                   List all decisions"
        Write-Host "  add --id <id> --title <title> [options]"
        Write-Host "    --decision <text>    The decision made"
        Write-Host "    --context <text>     Problem context"
        Write-Host "    --rationale <text>   Why this decision"
        Write-Host "    --status <status>    accepted|proposed|deprecated|rejected|deferred"
        Write-Host "    --confidence <lvl>   high|medium|low"
        Write-Host "    --tag <tag>          Tags (repeatable)"
        Write-Host "  update <id> [options]  Update decision properties"
        Write-Host "  remove <id>            Delete a decision"
        Write-Host ""
        Write-Host "Filters (for show/list):" -ForegroundColor Yellow
        Write-Host "  --tag <tag>            Filter by tag"
        Write-Host "  --status <status>      Filter by status"
        Write-Host "  --confidence <lvl>     Filter by confidence"
        Write-Host ""
    }
    default {
        # Backward compat: treat unknown action as query
        Show-Decisions -Query $Action
    }
}
