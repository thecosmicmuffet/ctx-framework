#!/usr/bin/env pwsh
# ctx start - Deterministic entry point

param(
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
    Write-Host "[git:$gitRoot ctx:$relativeCtx cmd:start:exists]" -ForegroundColor DarkGray
    Write-Host ""
}

# Display current iteration info
$stateFile = Join-Path $contextPath "state.md"
$todosFile = Join-Path $contextPath "TODOS.md"
$historyFile = Join-Path $contextPath "history.md"

Write-Host "=== ITERATION START ===" -ForegroundColor Cyan
Write-Host "Project: $projectName" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
Write-Host ""

# Current work from state.md
if (Test-Path $stateFile) {
    Write-Host "--- CURRENT WORK ---" -ForegroundColor Yellow
    $state = Get-Content $stateFile -Raw
    
    # Extract Active Work section
    if ($state -match '(?s)## Active Work\s*(.+?)(?=\n## |$)') {
        $activeWork = $matches[1].Trim()
        Write-Host $activeWork
    } else {
        Write-Host "(No active work defined in state.md)"
    }
    Write-Host ""
}

# Recent changes from history.md
if (Test-Path $historyFile) {
    Write-Host "--- RECENT HISTORY (last 5 entries) ---" -ForegroundColor Yellow
    $history = Get-Content $historyFile -Raw
    
    # Extract last 5 dated entries
    $entries = [regex]::Matches($history, '(?m)^### \d{4}-\d{2}-\d{2}.*?(?=\n### \d{4}|\z)')
    $recent = $entries | Select-Object -Last 5
    
    if ($recent) {
        foreach ($entry in $recent) {
            Write-Host $entry.Value.Trim()
            Write-Host ""
        }
    } else {
        Write-Host "(No history entries yet)"
        Write-Host ""
    }
}

# Top todos from TODOS.md
if (Test-Path $todosFile) {
    Write-Host "--- TOP PRIORITIES ---" -ForegroundColor Yellow
    $todos = Get-Content $todosFile -Raw
    
    # Extract uncompleted checkboxes (lines with - [ ] or ## [ ])
    $incomplete = [regex]::Matches($todos, '(?m)^[\s]*(?:- \[ \]|## \[ \]).*$')
    $top = $incomplete | Select-Object -First 5
    
    if ($top) {
        foreach ($item in $top) {
            Write-Host $item.Value.Trim()
        }
    } else {
        Write-Host "(No pending todos)"
    }
    Write-Host ""
}

Write-Host "=== Ready to proceed ===" -ForegroundColor Green
Write-Host ""
Write-Host "Commands: ctx state | ctx todos | ctx search <term> | ctx index | ctx finish"
