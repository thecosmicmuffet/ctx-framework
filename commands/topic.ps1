#!/usr/bin/env pwsh
# ctx topic - Progressive context expansion
# Topics are expandable detail nodes implementing wedge-shaped search

param(
    [Parameter(Position=0)]
    [string]$Action,  # topic name, or: new, archive, list (default)
    
    [Parameter(Position=1)]
    [string]$Name,
    
    [string]$Summary
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot ".." "lib" "config.ps1")

$contextPath = Get-CtxContextPath
$topicsDir = Join-Path $contextPath "topics"

function Get-Topics {
    if (-not (Test-Path $topicsDir)) { return @() }
    
    Get-ChildItem $topicsDir -Filter "*.md" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $summaryMatch = if ($content -match '(?s)## Summary\s*\n(.+?)(?=\n##|$)') { 
            $matches[1].Trim()
        } else { "(no summary)" }
        $truncated = if ($summaryMatch.Length -gt 60) { 
            $summaryMatch.Substring(0, 57) + "..." 
        } else { 
            $summaryMatch 
        }
        
        [PSCustomObject]@{
            Name = $_.BaseName
            Summary = $truncated
            Path = $_.FullName
        }
    }
}

function Show-TopicList {
    Write-Host "=== TOPICS ===" -ForegroundColor Cyan
    $topics = Get-Topics
    
    if ($topics.Count -eq 0) {
        Write-Host "(No topics defined)" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Create one with: ctx topic new <name>" -ForegroundColor Yellow
        return
    }
    
    $maxNameLen = ($topics | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
    foreach ($topic in $topics) {
        $padding = " " * ($maxNameLen - $topic.Name.Length + 2)
        Write-Host "  $($topic.Name)$padding" -NoNewline -ForegroundColor White
        Write-Host $topic.Summary -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "Expand with: ctx topic <name>" -ForegroundColor DarkGray
}

function Show-Topic {
    param([string]$TopicName)
    
    $topicPath = Join-Path $topicsDir "$TopicName.md"
    
    if (Test-Path $topicPath) {
        Write-Host "=== TOPIC: $TopicName ===" -ForegroundColor Cyan
        Write-Host ""
        Get-Content $topicPath -Raw
    } else {
        Write-Host "Topic '$TopicName' not found." -ForegroundColor Yellow
        Write-Host ""
        
        # Graceful degradation: suggest alternatives
        $topics = Get-Topics
        if ($topics.Count -gt 0) {
            Write-Host "Available topics:" -ForegroundColor Cyan
            foreach ($t in $topics) {
                Write-Host "  $($t.Name)" -ForegroundColor White
            }
            Write-Host ""
        }
        
        # Suggest search
        Write-Host "Try searching: ctx search $TopicName" -ForegroundColor DarkGray
        Write-Host "Or create it: ctx topic new $TopicName" -ForegroundColor DarkGray
    }
}

function New-Topic {
    param(
        [string]$TopicName,
        [string]$TopicSummary
    )
    
    if (-not (Test-Path $topicsDir)) {
        New-Item -ItemType Directory -Path $topicsDir -Force | Out-Null
    }
    
    $topicPath = Join-Path $topicsDir "$TopicName.md"
    
    if (Test-Path $topicPath) {
        Write-Host "Topic '$TopicName' already exists." -ForegroundColor Yellow
        Write-Host "Edit directly or use: ctx topic $TopicName" -ForegroundColor DarkGray
        return
    }
    
    $summaryText = if ($TopicSummary) { $TopicSummary } else { "Brief description of this topic." }
    
    $template = @"
# $TopicName

## Summary
$summaryText

## Current State
(What's true right now about this topic)

## Key Decisions
(Links to relevant entries in decisions.md or inline decisions)

## Details
(Expandable content - as much depth as needed)

## Related
- [Other relevant topics or decisions]
"@
    
    Set-Content -Path $topicPath -Value $template
    Write-Host "Created topic: $TopicName" -ForegroundColor Green
    Write-Host "Path: $topicPath" -ForegroundColor DarkGray
}

function Archive-Topic {
    param([string]$TopicName)
    
    $topicPath = Join-Path $topicsDir "$TopicName.md"
    $archiveDir = Join-Path $contextPath "archive" "topics"
    
    if (-not (Test-Path $topicPath)) {
        Write-Host "Topic '$TopicName' not found." -ForegroundColor Yellow
        return
    }
    
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }
    
    $archivePath = Join-Path $archiveDir "$TopicName-$(Get-Date -Format 'yyyy-MM').md"
    Move-Item -Path $topicPath -Destination $archivePath
    
    Write-Host "Archived topic: $TopicName" -ForegroundColor Green
    Write-Host "Location: $archivePath" -ForegroundColor DarkGray
}

# Main dispatch
switch -Regex ($Action) {
    '^$|^list$' {
        Show-TopicList
    }
    '^new$' {
        if (-not $Name) {
            Write-Host "Usage: ctx topic new <name> [--summary 'description']" -ForegroundColor Yellow
            return
        }
        New-Topic -TopicName $Name -TopicSummary $Summary
    }
    '^archive$' {
        if (-not $Name) {
            Write-Host "Usage: ctx topic archive <name>" -ForegroundColor Yellow
            return
        }
        Archive-Topic -TopicName $Name
    }
    default {
        # Treat action as topic name
        Show-Topic -TopicName $Action
    }
}
