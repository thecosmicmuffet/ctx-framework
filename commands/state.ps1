#!/usr/bin/env pwsh
# ctx state - CRUD for project state and work items

param(
    [Parameter(Position=0)]
    [string]$Action = "show",
    
    [Parameter(Position=1)]
    [string]$Arg1,
    
    [Parameter(Position=2)]
    [string]$Arg2,
    
    [string]$Id,
    [string]$Title,
    [string]$Phase,
    [string[]]$Tag,
    [ValidateSet("high", "medium", "low")]
    [string]$Confidence,
    [ValidateSet("next", "active", "blocked", "completed")]
    [string]$Status,
    [string[]]$Blockers,
    [switch]$ClearBlockers,
    [switch]$Summary,
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
    $relativeCtx = if ($gitRoot) { $contextPath -replace [regex]::Escape($gitRoot), "[git]" } else { $contextPath }
    $rootLabel = if ($gitRoot) { $gitRoot } else { "(concept)" }
    Write-Host "[git:$rootLabel ctx:$relativeCtx cmd:state:exists]" -ForegroundColor DarkGray
    Write-Host ""
}

# File paths — state data lives in state.dat (state.json is a wetlands stub)
$stateDat = Join-Path $contextPath "state.dat"
$stateStub = Join-Path $contextPath "state.json"

# Initialize state.dat if needed
function Initialize-State {
    if (-not (Test-Path $stateDat)) {
        $initial = @{
            version = "1.0"
            phase = "initial"
            updated = (Get-Date -Format 'yyyy-MM-dd')
            work_items = @()
            confidence = @{
                high = @()
                medium = @()
                low = @()
            }
        }
        $initial | ConvertTo-Json -Depth 10 | Set-Content $stateDat
    }
    # Ensure wetlands stub exists
    if (-not (Test-Path $stateStub) -or -not ((Get-Content $stateStub -First 1 -ErrorAction SilentlyContinue) -match 'PROTECTED')) {
        $stub = @"
// 🪺 PROTECTED WETLANDS — do not read directly
//
// This file is managed by ctx commands. Do not parse, grep, or edit it.
// USE: ctx state | ctx chart | ctx chart --set "> goal"
// Data is in state.dat. Use commands to maintain single source of truth.
"@
        Set-Content $stateStub $stub -Encoding UTF8
    }
}

# Load state
function Get-StateData {
    Initialize-State
    return Get-Content $stateDat -Raw | ConvertFrom-Json
}

# Save state
function Save-StateData {
    param($Data)
    $Data.updated = (Get-Date -Format 'yyyy-MM-dd')
    $Data | ConvertTo-Json -Depth 10 | Set-Content $stateDat
}

# Show summary
function Show-Summary {
    $data = Get-StateData
    
    Write-Host "=== PROJECT STATE ===" -ForegroundColor Cyan
    Write-Host "Phase: $($data.phase)" -ForegroundColor White
    Write-Host "Updated: $($data.updated)" -ForegroundColor Gray
    Write-Host ""
    
    $activeItems = $data.work_items | Where-Object { $_.status -eq "active" -or $_.status -eq "next" }
    if ($activeItems) {
        Write-Host "--- ACTIVE WORK ---" -ForegroundColor Yellow
        foreach ($item in $activeItems) {
            $statusIcon = if ($item.status -eq "active") { "[active]" } else { "[next]" }
            Write-Host "$statusIcon [$($item.id)] $($item.title)" -ForegroundColor Green
            if ($item.blockers -and $item.blockers.Count -gt 0) {
                Write-Host "   Blocked: $($item.blockers -join ', ')" -ForegroundColor Red
            }
        }
        Write-Host ""
    }
    
    Write-Host "--- CONFIDENCE ---" -ForegroundColor Yellow
    if ($data.confidence.high) { Write-Host "High: $($data.confidence.high.Count) items" -ForegroundColor Green }
    if ($data.confidence.medium) { Write-Host "Medium: $($data.confidence.medium.Count) items" -ForegroundColor Yellow }
    if ($data.confidence.low) { Write-Host "Low: $($data.confidence.low.Count) items" -ForegroundColor Red }
    Write-Host ""
}

# Show work items
function Show-WorkItems {
    param([string]$Query)
    
    $data = Get-StateData
    $items = $data.work_items
    
    if ($Status) { $items = $items | Where-Object { $_.status -eq $Status } }
    if ($Query) { $items = $items | Where-Object { $_.id -like "*$Query*" -or $_.title -like "*$Query*" } }
    
    if ($items) {
        Write-Host "=== WORK ITEMS ===" -ForegroundColor Cyan
        foreach ($item in $items) {
            Write-Host "[$($item.status)] [$($item.id)] $($item.title)" -ForegroundColor Green
            if ($item.blockers -and $item.blockers.Count -gt 0) {
                Write-Host "   Blockers: $($item.blockers -join ', ')" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No matching work items." -ForegroundColor Yellow
    }
}

# Set phase
function Set-Phase { param([string]$NewPhase); $data = Get-StateData; $data.phase = $NewPhase; Save-StateData $data; Write-Host "Phase: $NewPhase" -ForegroundColor Green }

# Add work item
function Add-WorkItem {
    param([string]$ItemId, [string]$ItemTitle, [string]$ItemStatus, [string[]]$ItemTags, [string]$ItemConfidence, [string[]]$ItemBlockers)
    if (-not $ItemId -or -not $ItemTitle) { Write-Error "Required: --id and --title"; return }
    $data = Get-StateData
    if ($data.work_items | Where-Object { $_.id -eq $ItemId }) { Write-Error "ID exists"; return }
    $newItem = [ordered]@{ id=$ItemId; title=$ItemTitle; status=if($ItemStatus){$ItemStatus}else{"next"}; tags=if($ItemTags){$ItemTags}else{@()}; confidence=if($ItemConfidence){$ItemConfidence}else{"medium"}; blockers=if($ItemBlockers){$ItemBlockers}else{@()} }
    $data.work_items += $newItem
    Save-StateData $data
    Write-Host "Added [$ItemId]: $ItemTitle" -ForegroundColor Green
}

# Update work item  
function Update-WorkItem {
    param([string]$ItemId, [string]$NewTitle, [string]$NewStatus, [string[]]$NewTags, [string]$NewConfidence, [string[]]$NewBlockers, [switch]$RemoveBlockers)
    $data = Get-StateData
    $item = $data.work_items | Where-Object { $_.id -eq $ItemId }
    if (-not $item) { Write-Error "Not found: $ItemId"; return }
    $changes = @()
    if ($NewTitle) { $item.title = $NewTitle; $changes += "title" }
    if ($NewStatus) { $item.status = $NewStatus; $changes += "status" }
    if ($NewTags) { $item.tags = $NewTags; $changes += "tags" }
    if ($NewConfidence) { $item.confidence = $NewConfidence; $changes += "confidence" }
    if ($NewBlockers) { $item.blockers = $NewBlockers; $changes += "blockers" }
    if ($RemoveBlockers) { $item | Add-Member -NotePropertyName "blockers" -NotePropertyValue @() -Force; $changes += "cleared blockers" }
    if ($changes.Count -eq 0) { Write-Host "No changes." -ForegroundColor Yellow; return }
    Save-StateData $data
    Write-Host "[$ItemId] updated: $($changes -join ', ')" -ForegroundColor Green
}

# Remove work item
function Remove-WorkItem {
    param([string]$ItemId)
    $data = Get-StateData
    $before = $data.work_items.Count
    $data.work_items = @($data.work_items | Where-Object { $_.id -ne $ItemId })
    if ($data.work_items.Count -eq $before) { Write-Error "Not found"; return }
    Save-StateData $data
    Write-Host "Removed [$ItemId]" -ForegroundColor Yellow
}

# Set arbitrary property (supports dot notation for nested: implementation_readiness.feature.status)
function Set-Property {
    param([string]$Path, [string]$Value)
    $data = Get-StateData
    
    $parts = $Path -split '\.'
    $current = $data
    
    # Navigate/create path except last element
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $part = $parts[$i]
        if (-not $current.PSObject.Properties[$part]) {
            $current | Add-Member -NotePropertyName $part -NotePropertyValue ([PSCustomObject]@{}) -Force
        }
        $current = $current.$part
    }
    
    # Set final property
    $finalPart = $parts[-1]
    
    # Try to parse value as JSON, fall back to string
    try {
        $parsedValue = $Value | ConvertFrom-Json -ErrorAction Stop
        $current | Add-Member -NotePropertyName $finalPart -NotePropertyValue $parsedValue -Force
    } catch {
        $current | Add-Member -NotePropertyName $finalPart -NotePropertyValue $Value -Force
    }
    
    Save-StateData $data
    Write-Host "✓ Set $Path" -ForegroundColor Green
}

# Remove property (supports dot notation)
function Remove-Property {
    param([string]$Path)
    $data = Get-StateData
    
    $parts = $Path -split '\.'
    $current = $data
    
    # Navigate to parent
    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $part = $parts[$i]
        if (-not $current.PSObject.Properties[$part]) {
            Write-Error "Path not found: $Path"
            return
        }
        $current = $current.$part
    }
    
    # Remove final property
    $finalPart = $parts[-1]
    if ($current.PSObject.Properties[$finalPart]) {
        $current.PSObject.Properties.Remove($finalPart)
        Save-StateData $data
        Write-Host "✓ Removed $Path" -ForegroundColor Yellow
    } else {
        Write-Error "Property not found: $finalPart"
    }
}

# Get property value (supports dot notation)
function Get-Property {
    param([string]$Path)
    $data = Get-StateData
    
    $parts = $Path -split '\.'
    $current = $data
    
    foreach ($part in $parts) {
        if (-not $current.PSObject.Properties[$part]) {
            Write-Host "Not found: $Path" -ForegroundColor Yellow
            return
        }
        $current = $current.$part
    }
    
    $current | ConvertTo-Json -Depth 5
}

# Main router
switch ($Action.ToLower()) {
    "show" { if ($Arg1) { Show-WorkItems -Query $Arg1 } else { Show-Summary } }
    "items" { Show-WorkItems -Query $Arg1 }
    "phase" { if ($Arg1 -or $Phase) { Set-Phase -NewPhase $(if($Arg1){$Arg1}else{$Phase}) } else { $d=Get-StateData; Write-Host "Phase: $($d.phase)" } }
    "add" { Add-WorkItem -ItemId $Id -ItemTitle $Title -ItemStatus $Status -ItemTags $Tag -ItemConfidence $Confidence -ItemBlockers $Blockers }
    "update" { if (-not $Arg1 -and -not $Id) { Write-Error "Usage: ctx state update <id> ..."; exit 1 }; Update-WorkItem -ItemId $(if($Arg1){$Arg1}else{$Id}) -NewTitle $Title -NewStatus $Status -NewTags $Tag -NewConfidence $Confidence -NewBlockers $Blockers -RemoveBlockers:$ClearBlockers }
    "remove" { if (-not $Arg1) { Write-Error "Usage: ctx state remove <id>"; exit 1 }; Remove-WorkItem -ItemId $Arg1 }
    "set" { 
        if (-not $Arg1 -or -not $Arg2) { Write-Error "Usage: ctx state set <path> <value>`nExample: ctx state set phase Implementation"; exit 1 }
        Set-Property -Path $Arg1 -Value $Arg2
    }
    "unset" {
        if (-not $Arg1) { Write-Error "Usage: ctx state unset <path>`nExample: ctx state unset next_steps"; exit 1 }
        Remove-Property -Path $Arg1
    }
    "get" {
        if (-not $Arg1) { Write-Error "Usage: ctx state get <path>`nExample: ctx state get phase"; exit 1 }
        Get-Property -Path $Arg1
    }
    "help" { 
        Write-Host "ctx state - CRUD for project state" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  show [query]      Show summary or search work items"
        Write-Host "  items [query]     List work items"
        Write-Host "  phase [value]     Get/set phase"
        Write-Host "  get <path>        Get property value (dot notation)"
        Write-Host "  set <path> <val>  Set property (creates path, JSON or string)"
        Write-Host "  unset <path>      Remove property"
        Write-Host "  add               Add work item (--id --title [--status --tag])"
        Write-Host "  update <id>       Update work item"
        Write-Host "  remove <id>       Remove work item"
        Write-Host ""
        Write-Host "Path examples:" -ForegroundColor Yellow
        Write-Host "  phase                              Simple property"
        Write-Host "  implementation_readiness.feature   Nested property"
        Write-Host ""
    }
    default { Show-Summary }
}
