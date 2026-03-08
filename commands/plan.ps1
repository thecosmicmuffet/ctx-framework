#!/usr/bin/env pwsh
# ctx plan - Command discovery and planning workflow guide

param(
    [switch]$Help,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

if (-not $Quiet) {
    Write-Host "[ctx:plan]" -ForegroundColor DarkGray
    Write-Host ""
}

if ($Help) {
    Write-Host "=== WEDGE-BASED PLANNING WORKFLOW ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Instead of reading full files, use commands to query exactly what you need:" -ForegroundColor White
    Write-Host ""
    Write-Host "1. SURVEY CURRENT STATE" -ForegroundColor Yellow
    Write-Host "   ctx state                  # What's happening? Phase, active work, confidence" -ForegroundColor Gray
    Write-Host "   ctx state --confidence low # What needs attention?" -ForegroundColor Gray
    Write-Host "   ctx state --blockers       # What's blocked?" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. REVIEW RELEVANT DECISIONS" -ForegroundColor Yellow
    Write-Host "   ctx decision --tag <area>  # Find decisions by tag (tiles, viewmodel, etc.)" -ForegroundColor Gray
    Write-Host "   ctx decision <id>          # Get specific decision details" -ForegroundColor Gray
    Write-Host "   ctx decision --status accepted  # See accepted decisions only" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. LOCATE CODE" -ForegroundColor Yellow
    Write-Host "   ctx codebase find <term>   # Find files/patterns" -ForegroundColor Gray
    Write-Host "   ctx codebase --tag <area>  # Filter by tag" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. MANAGE WORK" -ForegroundColor Yellow
    Write-Host "   ctx todos                  # See work queue" -ForegroundColor Gray
    Write-Host "   ctx todos add <title>      # Add work item" -ForegroundColor Gray
    Write-Host "   ctx todos complete <id>    # Mark done" -ForegroundColor Gray
    Write-Host ""
    Write-Host "5. UPDATE CONTEXT (directly edit JSON)" -ForegroundColor Yellow
    Write-Host "   decisions.json   # Add/update architectural decisions" -ForegroundColor Gray
    Write-Host "   state.json       # Update work items, confidence" -ForegroundColor Gray
    Write-Host "   codebase.json    # Map code locations" -ForegroundColor Gray
    Write-Host ""
    Write-Host "6. FINISH ITERATION" -ForegroundColor Yellow
    Write-Host "   ctx finish       # Complete work, update history" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

Write-Host "=== CTX PLANNING COMMANDS ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Expand Context:" -ForegroundColor Yellow
Write-Host "  ctx topic                   " -ForegroundColor White -NoNewline
Write-Host "List available depth topics" -ForegroundColor Gray
Write-Host "  ctx topic <name>            " -ForegroundColor White -NoNewline
Write-Host "Expand into topic detail" -ForegroundColor Gray
Write-Host "  ctx topic new <name>        " -ForegroundColor White -NoNewline
Write-Host "Create new topic" -ForegroundColor Gray
Write-Host ""

Write-Host "Review & Triage:" -ForegroundColor Yellow
Write-Host "  ctx decision [--tag <tag>] [--status <status>]" -ForegroundColor White
Write-Host "     Find architectural decisions (filter by tag/status/confidence)" -ForegroundColor Gray
Write-Host ""
Write-Host "  ctx state [--confidence <level>] [--blockers]" -ForegroundColor White
Write-Host "     Current work, confidence levels, blocked items" -ForegroundColor Gray
Write-Host ""
Write-Host "  ctx todos [--depth N]" -ForegroundColor White
Write-Host "     Work queue with progress tracking" -ForegroundColor Gray
Write-Host ""
Write-Host "  ctx codebase find <term> [--tag <tag>]" -ForegroundColor White
Write-Host "     Locate files, patterns, and code structure" -ForegroundColor Gray
Write-Host ""

Write-Host "Make Progress:" -ForegroundColor Yellow
Write-Host "  ctx todos add <title> [--details <text>]" -ForegroundColor White
Write-Host "     Add new work item" -ForegroundColor Gray
Write-Host ""
Write-Host "  ctx todos complete <id> [--note <text>]" -ForegroundColor White
Write-Host "     Mark work complete (auto-updates history)" -ForegroundColor Gray
Write-Host ""

Write-Host "Document:" -ForegroundColor Yellow
Write-Host "  Edit JSON files directly:" -ForegroundColor White
Write-Host "     decisions.json  - Architectural decisions with tags" -ForegroundColor Gray
Write-Host "     state.json      - Work items, confidence tracking" -ForegroundColor Gray
Write-Host "     codebase.json   - Code location map" -ForegroundColor Gray
Write-Host ""

Write-Host "Handoff:" -ForegroundColor Yellow
Write-Host "  ctx finish [--continue-mission]" -ForegroundColor White
Write-Host "     Complete iteration, update history, prepare for next agent" -ForegroundColor Gray
Write-Host ""

Write-Host "Use: ctx plan --help  for workflow guide" -ForegroundColor DarkGray
