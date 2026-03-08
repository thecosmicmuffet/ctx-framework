#!/usr/bin/env pwsh
# ctx bootstrap - Initialize context for a new project

param(
    [string]$ContextDir = ".ctx",
    [string]$ProjectName = ""
)

$ErrorActionPreference = 'Stop'

Write-Host "=== ctx bootstrap ===" -ForegroundColor Cyan
Write-Host "Target: $ContextDir"
Write-Host ""

# Check if context already exists
if (Test-Path $ContextDir) {
    Write-Host "⚠ Context directory already exists: $ContextDir" -ForegroundColor Yellow
    $response = Read-Host "Overwrite? (y/N)"
    if ($response -notmatch '^[Yy]$') {
        Write-Host "Aborted."
        exit 1
    }
}

# Create directory structure
New-Item -ItemType Directory -Path $ContextDir -Force | Out-Null
New-Item -ItemType Directory -Path "$ContextDir\handoffs" -Force | Out-Null

Write-Host "✓ Created directory structure" -ForegroundColor Green

# Create state.json (source of truth)
$stateJson = @{
    project = "[Your Project Name]"
    owner = "[Your Name]"
    branch = "[Branch Name]"
    updated = Get-Date -Format 'yyyy-MM-dd'
    phase = @{
        name = "Bootstrap"
        focus = "Foundation & context establishment"
    }
    work_items = @(
        @{
            id = "bootstrap"
            title = "Complete bootstrap initialization"
            status = "in-progress"
            description = "Set up project structure and define mission/scope"
            tags = @("setup", "foundation")
            confidence = "low"
            blockers = @()
        }
    )
    confidence = @{
        high = @("Context structure created")
        medium = @()
        low = @("Mission definition", "Success criteria", "Codebase inventory")
    }
    next_steps = @(
        "Complete mission statement"
        "Inventory codebase"
        "Define success criteria"
    )
}

$stateJson | ConvertTo-Json -Depth 10 | Set-Content -Path "$ContextDir\state.json"
Write-Host "✓ Created state.json" -ForegroundColor Green

# Create state.md
$stateContent = @'
# Project State

**Project:** [Your Project Name]
**Owner:** [Your Name]
**Branch:** [Branch Name]
**Updated:** {0}

## Current Phase

**Phase:** Bootstrap
**Focus:** Foundation & context establishment

## Active Work

### Now
- Setting up project structure
- Defining mission and scope

### Next
1. Complete mission statement
2. Inventory codebase
3. Define success criteria

## Blockers

None currently.

## Confidence Notes

### High Confidence (validated)
- None yet

### Medium Confidence (implemented, not validated)
- None yet

### Low Confidence (not started)
- Everything

## Key Files

**Modified recently:**
- None yet

**Need work next:**
- TBD based on mission

## Build Status

Last build: Not attempted
Tests: Not run

## Open Questions

1. What is the core mission?
2. What are the success criteria?
3. What are the key constraints?

---

*This file tracks: What is happening NOW*
*See: history.md for what happened, decisions.md for why*
'@ -f (Get-Date -Format 'yyyy-MM-dd')

Set-Content -Path "$ContextDir\state.md" -Value $stateContent
Write-Host "✓ Created state.md (generated from state.json)" -ForegroundColor Green

# Create decisions.json (source of truth)
$decisionsJson = @{
    decisions = @(
        @{
            id = "ctx"
            title = "Use ctx for context management"
            date = Get-Date -Format 'yyyy-MM-dd'
            status = "accepted"
            context = "Need structured approach to maintain project context across agent sessions"
            decision = "Use ctx with JSON source + MD views, wedge-based querying"
            alternatives = @(
                "Manual markdown files - too fragmented"
                "Monolithic README - doesn't scale"
            )
            rationale = "Framework provides structure, commands, and avoids context duplication"
            consequences = @{
                positive = @("Structured context", "Query commands", "Extensible")
                negative = @("Learning curve", "Requires discipline")
            }
            confidence = "high"
            tags = @("infrastructure", "context")
            related = @()
        }
    )
}

$decisionsJson | ConvertTo-Json -Depth 10 | Set-Content -Path "$ContextDir\decisions.json"
Write-Host "✓ Created decisions.json" -ForegroundColor Green

# Create decisions.md
$decisionsContent = @'
# Architectural Decisions

**Project:** [Your Project Name]
**Updated:** {0}

## Core Decisions

### [Decision Title]
**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated

**Context:**
Why this decision is needed.

**Decision:**
What was decided.

**Alternatives Considered:**
- Option A: ...
- Option B: ...

**Rationale:**
Why this path was chosen.

**Consequences:**
- Positive: ...
- Negative: ...

**Confidence:** High | Medium | Low

---

*This file tracks: WHY things are this way*
*See: state.md for current work, history.md for timeline*
'@ -f (Get-Date -Format 'yyyy-MM-dd')

Set-Content -Path "$ContextDir\decisions.md" -Value $decisionsContent
Write-Host "✓ Created decisions.md (generated from decisions.json)" -ForegroundColor Green

# Create codebase.json (source of truth)
$codebaseJson = @{
    entries = @(
        @{
            id = "core-impl"
            type = "structure"
            description = "Core implementation files"
            tags = @("core")
            locations = @()
            search_hints = @("*.cpp", "*.h")
            patterns = @()
        }
    )
}

$codebaseJson | ConvertTo-Json -Depth 10 | Set-Content -Path "$ContextDir\codebase.json"
Write-Host "✓ Created codebase.json" -ForegroundColor Green

# Create todos.json (source of truth)
$todosJson = @{
    todos = @(
        @{
            id = 1
            title = "Define project mission"
            description = "Complete mission statement in state.md"
            status = "not-started"
            tags = @("setup")
            confidence = "low"
            blockers = @()
        }
        @{
            id = 2
            title = "Inventory codebase"
            description = "Map key files and patterns to codebase.json"
            status = "not-started"
            tags = @("discovery")
            confidence = "low"
            blockers = @()
        }
    )
    next_id = 3
}

$todosJson | ConvertTo-Json -Depth 10 | Set-Content -Path "$ContextDir\todos.json"
Write-Host "✓ Created todos.json" -ForegroundColor Green

# Create history.md
$historyContent = @'
# Project History

**Project:** [Your Project Name]
**Started:** {0}

## Timeline (Reverse Chronological)

### {0} - Project Initialized
**Iteration:** 1
**Phase:** Bootstrap

**Completed:**
- Created context structure with ctx

**Files Changed:**
- Created .ctx/ structure

**Decisions:**
- Using ctx for context management

**Learnings:**
- None yet

**Next:**
- Define mission and scope
- Complete state.md with project details

---

*This file tracks: WHAT happened WHEN*
*See: state.md for current work, decisions.md for why*
'@ -f (Get-Date -Format 'yyyy-MM-dd')

Set-Content -Path "$ContextDir\history.md" -Value $historyContent
Write-Host "✓ Created history.md" -ForegroundColor Green

# Create codebase.md
$codebaseContent = @'
# Codebase Reference

**Project:** [Your Project Name]
**Updated:** {0}

## Key Files

### Core Implementation
- `path/to/file.cpp` - Brief description
- `path/to/file.h` - Brief description

### Tests
- `path/to/test.cpp` - Test coverage

### Build/Config
- `Solution.sln` - Main solution
- `project.vcxproj` - Project file

## Patterns & Conventions

### Naming
- Classes: PascalCase
- Methods: PascalCase
- Variables: camelCase

### Architecture
- Pattern: Description
- Convention: Description

## Dependencies

### External
- Library: Purpose
- SDK: Purpose

### Internal
- Module: Purpose

## Hot Paths

Files frequently modified together:
- Group 1: file1, file2, file3
- Group 2: file4, file5

## Search Tips

**Find X:** `grep -r "pattern" path/`
**Find Y:** `grep -r "pattern" path/`

---

*This file tracks: WHERE things are*
*See: state.md for what needs changing, decisions.md for patterns*
'@ -f (Get-Date -Format 'yyyy-MM-dd')

Set-Content -Path "$ContextDir\codebase.md" -Value $codebaseContent
Write-Host "✓ Created codebase.md (generated from codebase.json)" -ForegroundColor Green

# DO NOT create MIGRATION.md - deprecated
# Old projects can reference ctx docs for migration guidance

# Create guide.md
$guideContent = @'
# Context Navigation Guide

**Project:** [Your Project Name]

## Quick Start (< 5 minutes)

### New Agent Onboarding
1. **Read this file** (1 min) - Orientation
2. **Read state.md** (2 min) - Current work and confidence levels
3. **Skim decisions.md** (2 min) - Why things are this way
4. **Reference codebase.md** (as needed) - Where things are
5. **Check history.md** (as needed) - What happened before

### Resuming Work
1. **state.md** - What's in progress?
2. **decisions.md** - What are the constraints?
3. **codebase.md** - Where do I make changes?

## File Purposes

| File | Purpose | Read When | Size Limit |
|------|---------|-----------|------------|
| guide.md | Navigation | Starting fresh | ~200 lines |
| state.md | Current work | Always | ~200 lines |
| decisions.md | Architecture | Making changes | ~300 lines |
| codebase.md | File locations | Searching | ~300 lines |
| history.md | Timeline | Investigating | ~400 lines |
| handoffs/ | Archives | Deep history | No limit |

## Confidence Levels

**High Confidence:** Validated, working, trust it
**Medium Confidence:** Implemented but not fully tested
**Low Confidence:** Planned or speculative

Use confidence levels from state.md to prioritize validation work.

## Context Hygiene

### Keep Files Bounded
- state.md: ~200 lines (if larger, archive to handoffs/)
- decisions.md: ~300 lines (keep only active decisions)
- codebase.md: ~300 lines (references, not documentation)
- history.md: ~400 lines (archive old iterations to handoffs/)

### Archive Strategy
When files grow too large:
1. Create `handoffs/YYYY-MM-DD-milestone.md` with full context
2. Trim parent file to recent entries
3. Link to handoff in parent file

### Staleness
Files become stale when they haven't been updated recently:
- Review weekly or per-iteration
- Mark stale sections with `[STALE: YYYY-MM-DD]`
- Verify before trusting

## Working with ctx CLI

```powershell
# From scripts/ctx/
.\ctx.ps1                    # Show available commands
.\ctx.ps1 index ..\..\.ctx  # List context files with staleness
.\ctx.ps1 search term        # Search context (if implemented)
```

```bash
# Or using bash version
./ctx                        # Show available commands
./ctx index ../../.ctx   # List context files with staleness
./ctx search term            # Search context (if implemented)
```

## When to Update What

| Event | Update |
|-------|--------|
| Start work on task | state.md (Now section) |
| Complete task | state.md (move to Just Completed), history.md |
| Make architectural decision | decisions.md |
| Discover important file | codebase.md |
| Hit milestone | Create handoff, trim files |
| Find blocking issue | state.md (Blockers section) |

## Getting Help

**Unclear mission?** Read decisions.md for context
**Can't find file?** Check codebase.md
**Why was X decided?** Search decisions.md
**What happened last?** Read history.md top entries

## Disposal

When project completes:
```bash
./ctx honor .
```

Then archive .ctx/ with project notes.

---

*This file is your map. Trust it. Update it when lost.*
'@

Set-Content -Path "$ContextDir\guide.md" -Value $guideContent
Write-Host "✓ Created guide.md" -ForegroundColor Green

# Note about JSON-backed context
Write-Host ""
Write-Host "=== JSON-Backed Context ===" -ForegroundColor Cyan
Write-Host "Created JSON source files (state.json, decisions.json, codebase.json, todos.json)" -ForegroundColor Green
Write-Host "Markdown files are VIEWS - edit JSON, regenerate MD as needed" -ForegroundColor Yellow
Write-Host "Use ctx commands: decision, state, todos, codebase (query without full file reads)" -ForegroundColor Yellow

# Create MIGRATION.md (for projects migrating from old protocols)
$migrationContent = @'
# Migration from Old Context Protocol

**[DEPRECATED]** - This file is retained for legacy reference only.

**If you're starting fresh, ignore this file entirely.**

## Modern ctx Approach

The current ctx uses:
- **JSON source files** (state.json, decisions.json, codebase.json, todos.json)
- **MD view files** (generated from JSON, not edited directly)
- **Query commands** (ctx decision, ctx state, ctx todos, ctx codebase)
- **Wedge-based querying** (tags enable selective reads, not full-file)

## For Legacy Projects

If migrating from old iteration-based JSON protocol:
1. Use current bootstrap.ps1 to create modern structure
2. Manually extract key context into JSON files
3. Archive old files to .ctx/archive/
4. Do NOT recreate old MIGRATION.md patterns

## Key Philosophy Shifts

**Old:** Metaphorical language, iteration ceremony, full-file context
**New:** Functional, wedge-based, JSON-backed, command-driven

---

*This file is deprecated. Future agents should ignore it.*
'@

Set-Content -Path "$ContextDir\MIGRATION.md" -Value $migrationContent
Write-Host "✓ Created MIGRATION.md (deprecated, for legacy reference only)" -ForegroundColor Yellow

# Create .ctxconfig for path resolution
Write-Host ""
Write-Host "=== Initializing Path Resolution ===" -ForegroundColor Cyan

# Detect git root
$GitRoot = $null
try {
    $GitRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0 -and $GitRoot) {
        $GitRoot = $GitRoot.Replace('/', '\')
        Write-Host "✓ Git root detected: $GitRoot" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Git root not detected (not in a git repository)" -ForegroundColor Yellow
}

# Detect project root (where we're running from)
$ProjectRoot = (Get-Location).Path

# Detect solution files
$SolutionFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.sln" -ErrorAction SilentlyContinue
$SolutionPath = if ($SolutionFiles) { 
    $SolutionFiles[0].Name
    Write-Host "✓ Solution file detected: $($SolutionFiles[0].Name)" -ForegroundColor Green
    "[project]\$($SolutionFiles[0].Name)"
} else {
    Write-Host "⚠ No solution file detected" -ForegroundColor Yellow
    $null
}

# Detect language
$Language = "unknown"
$CppFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.cpp" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$CsFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.cs" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
$PyFiles = Get-ChildItem -Path $ProjectRoot -Filter "*.py" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

if ($CppFiles) { $Language = "cpp" }
elseif ($CsFiles) { $Language = "csharp" }
elseif ($PyFiles) { $Language = "python" }

Write-Host "✓ Language detected: $Language" -ForegroundColor Green

# Get or prompt for project name
if (-not $ProjectName) {
    $ProjectName = Read-Host "Project name (for multi-project support)"
    if (-not $ProjectName) {
        $ProjectName = Split-Path -Leaf $ProjectRoot
    }
}

# Build config paths
$RelativeContextDir = if ($GitRoot) {
    "[project]\$ContextDir"
} else {
    ".\$ContextDir"
}

$RelativeProjectRoot = if ($GitRoot) {
    $ProjectRoot.Replace($GitRoot, '[git]').TrimStart('\')
} else {
    "."
}

$FrameworkDir = if ($GitRoot) {
    $PSScriptRoot.Replace($GitRoot, '[git]').TrimStart('\')
} else {
    $PSScriptRoot
}

# Create .ctxconfig
$ConfigPath = Join-Path $ProjectRoot ".ctxconfig"
$Config = @{
    version = "1.0"
    current_project = $ProjectName
    projects = @{
        $ProjectName = @{
            git_root = $GitRoot
            project_root = $RelativeProjectRoot
            context_dir = $RelativeContextDir
            framework_dir = $FrameworkDir
            anchors = @{
                solution = $SolutionPath
                language = $Language
            }
            last_verified = (Get-Date -Format "o")
        }
    }
    breadcrumbs = @{
        $ProjectName = @()
    }
}

$Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
Write-Host "✓ Created .ctxconfig" -ForegroundColor Green

Write-Host ""
Write-Host "=== Bootstrap Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cd $ContextDir" -ForegroundColor Gray
Write-Host "2. Edit state.json with your project details (then regenerate state.md)" -ForegroundColor Gray
Write-Host "3. Fill in guide.md with project name" -ForegroundColor Gray
Write-Host "4. Add first decision to decisions.json" -ForegroundColor Gray
Write-Host ""
Write-Host "Available commands (from project root):" -ForegroundColor Cyan
Write-Host "  .\scripts\ctx\ctx.ps1 plan      # Command discovery" -ForegroundColor Gray
Write-Host "  .\scripts\ctx\ctx.ps1 start     # Begin work iteration" -ForegroundColor Gray
Write-Host "  .\scripts\ctx\ctx.ps1 todos     # Manage tasks" -ForegroundColor Gray
Write-Host "  .\scripts\ctx\ctx.ps1 decision  # Query decisions" -ForegroundColor Gray
Write-Host "  .\scripts\ctx\ctx.ps1 state     # Query state" -ForegroundColor Gray
Write-Host ""
Write-Host "Path resolution configured for project: $ProjectName" -ForegroundColor Cyan
Write-Host "  Git root: $(if ($GitRoot) { $GitRoot } else { 'N/A' })" -ForegroundColor Gray
Write-Host "  Context: $RelativeContextDir" -ForegroundColor Gray
Write-Host ""
