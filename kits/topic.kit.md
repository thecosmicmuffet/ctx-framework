# topic.kit.md - Progressive Context Expansion

## Overview

Topics are **expandable detail nodes** in the context hierarchy. They implement the "wedge-shaped search" pattern:

- Start with minimal state (thin client)
- Expand into relevant topic on demand
- Each topic is a "save point" that can be re-expanded
- Topics act as **attractor basins** organizing the search space

## Directory Structure

```
.ctx/
  state.md              # Minimal: phase, focus, blockers (< 50 lines)
  topics/               # Expandable detail
    <topic-name>.md     # Each topic is self-contained
  archive/              # Compressed history (fiscal year scope)
```

## Topic File Format

```markdown
# <Topic Name>

## Summary
One paragraph: what this topic covers, why it matters.

## Current State
What's true right now about this topic.

## Key Decisions
Links to relevant entries in decisions.md (or inline if topic-specific).

## Details
The expandable content - as much depth as needed.

## Related
- [Other Topic](./other-topic.md)
- [Decision: Architecture Choice](../decisions.md#architecture-choice)
```

## Commands

### ctx topic
List all available topics with one-line summaries.

```powershell
ctx topic
# Output:
# Topics:
#   tom-coverage      TOM test mapping to vendor plan (100% complete)
#   cloudtest         Pipeline setup and artifact flow
#   taef-setup        VM and TAEF configuration for local testing
#   context-menu-uia  WinUI popup detection patterns
```

### ctx topic <name>
Expand into a specific topic, displaying its full content.

```powershell
ctx topic tom-coverage
# Output: Full content of topics/tom-coverage.md
```

### ctx topic new <name>
Create a new topic file with template.

### ctx topic archive <name>
Move topic to archive (narrative compression).

## Integration with Phase Cycle

- **Parse**: Unknown input → search topics for matches
- **Rejoin**: `ctx start` shows topic list as available depths
- **Adapt**: `ctx topic new/archive` for pruning
- **Yield**: Topics remain as save points for next cycle

## Attractor Basins

Topics should cluster around natural project concepts:
- **Surfaces** (UI areas: Pins, AllApps, Recommendations)
- **Infrastructure** (build, test, deploy)
- **Technical patterns** (UIA, XAML, TAEF)
- **Process** (PR workflow, review, integration)

## Implementation Notes

```powershell
# topic.ps1

function Get-Topics {
    $topicsDir = Join-Path $contextPath "topics"
    if (-not (Test-Path $topicsDir)) { return @() }
    
    Get-ChildItem $topicsDir -Filter "*.md" | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $summary = if ($content -match '## Summary\s*\n(.+?)(?=\n##|$)') { 
            $matches[1].Trim().Substring(0, [Math]::Min(60, $matches[1].Trim().Length))
        } else { "(no summary)" }
        
        [PSCustomObject]@{
            Name = $_.BaseName
            Summary = $summary
            Path = $_.FullName
        }
    }
}

function Show-Topic {
    param([string]$Name)
    $topicPath = Join-Path $contextPath "topics" "$Name.md"
    if (Test-Path $topicPath) {
        Get-Content $topicPath -Raw
    } else {
        Write-Host "Topic '$Name' not found." -ForegroundColor Yellow
        Write-Host "Available topics:" -ForegroundColor Cyan
        Get-Topics | ForEach-Object { Write-Host "  $($_.Name)" }
        Write-Host ""
        Write-Host "Did you mean to search? Try: ctx search $Name"
    }
}
```

## Graceful Degradation

When topic not found:
1. List available topics
2. Suggest `ctx search <term>`
3. Suggest `ctx topic new <name>` if creating
4. Log the miss for later routinization

Never return vague failure that triggers agent self-sufficiency.
