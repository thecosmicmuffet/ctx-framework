# narrative.kit.md - History as Story, Not Archive

## Overview

History serves as a **comfortable launching point** for reconsidering current effort, not a dogmatically complete data store. Value drift means archives cannot survive past a certain point regardless of completeness.

## The Generational Principle

Stories told now about 500 years ago share characteristics with stories told 500 years ago about 1000 years ago. What matters:

1. **Embodied experience** - Can we relate to it now?
2. **Testimony matching** - Does it connect to what we know?
3. **Narrative coherence** - Does it tell a meaningful story?

Raw data matters less than the story it tells.

## Fiscal Year Scope

History should be reviewable on a **fiscal year** horizon, answering:

1. **What have we contributed?** (outputs, deliverables)
2. **How was it effective?** (impact, adoption, feedback)
3. **Where was there room for improvement?** (lessons, gaps)
4. **How have we learned durably?** (changes that stuck)

## File Structure

```
.ctx/
  history.md            # Current fiscal year narrative
  archive/
    FY25-narrative.md   # Previous year's story
    FY24-narrative.md   # Older narrative (compressed)
```

## history.md Format

```markdown
# Project History

## Narrative Summary
Three paragraphs maximum: What this project is, what it achieved, where it's going.

## Recent Chapters (Current FY)

### Chapter: <Theme> (<Date Range>)
**Contribution:** What was built/delivered
**Effectiveness:** How it was received, impact
**Lessons:** What we learned
**Durability:** What changed permanently

### Chapter: TOM Test Coverage (Feb-Mar 2026)
**Contribution:** 86 tests achieving 100% vendor plan coverage
**Effectiveness:** Validated on live VM, all tests passing
**Lessons:** WinUI context menus need 300ms delay, CategoryView headers must be skipped
**Durability:** Patterns documented in decisions.md, code handles edge cases

## Timeline (Compressed)
- 2026-03-03: 86/86 tests passing, PR ready for signoff
- 2026-03-02: Fixed CategoryView parsing, 53→72 tests passing
- 2026-02-27: TOM PR submitted with pin reorder methods
- 2026-02-26: CloudTest integration PR, vendor test plan mapped
```

## Commands

### ctx history
Show narrative summary and recent chapters.

### ctx history chapter <title>
Add a new chapter to current history.

### ctx history archive
Compress current FY to archive, start fresh.

### ctx history search <term>
Search across all history (current and archived).

## Compression Rules

When archiving a fiscal year:

1. **Keep narrative summary** (3 paragraphs max)
2. **Keep chapter titles and contributions** (bullet list)
3. **Keep durability items** (what changed permanently)
4. **Discard raw timeline entries** (they served their purpose)
5. **Discard room-for-improvement** (we either learned or we didn't)

## Integration with Phase Cycle

- **Rejoin**: History provides appreciation context
- **Adapt**: New chapters added as work completes
- **Yield**: History is the record of yielded work

## Anti-Patterns

❌ **Endless append** - History grows without compression
❌ **Raw data dump** - Dates/commits without narrative
❌ **Completeness obsession** - Trying to capture everything
❌ **Disconnected entries** - Items that don't relate to current work

## Implementation

```powershell
# narrative.ps1 (history command enhancement)

function Add-Chapter {
    param(
        [string]$Title,
        [string]$Contribution,
        [string]$Effectiveness,
        [string]$Lessons,
        [string]$Durability
    )
    
    $chapter = @"

### Chapter: $Title ($(Get-Date -Format 'MMM yyyy'))
**Contribution:** $Contribution
**Effectiveness:** $Effectiveness
**Lessons:** $Lessons
**Durability:** $Durability
"@
    
    # Insert after "## Recent Chapters" header
    # ... implementation
}

function Compress-FiscalYear {
    # Move current history.md to archive/FY<year>-narrative.md
    # Apply compression rules
    # Start fresh history.md with summary carried forward
}
```
