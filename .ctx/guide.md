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

```bash
# From scripts/ctx/
./ctx                    # Show available commands
./ctx index ../.ctx  # List context files with staleness
./ctx search term        # Search context (if implemented)
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
