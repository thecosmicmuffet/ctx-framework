#!/usr/bin/env bash
# ctx bootstrap - Initialize context for a new project

set -e

CONTEXT_DIR="${1:-.ctx}"

echo "=== ctx bootstrap ==="
echo "Target: $CONTEXT_DIR"
echo ""

# Check if context already exists
if [ -d "$CONTEXT_DIR" ]; then
    echo "⚠ Context directory already exists: $CONTEXT_DIR"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Create directory structure
mkdir -p "$CONTEXT_DIR"
mkdir -p "$CONTEXT_DIR/handoffs"

echo "✓ Created directory structure"

# Create state.md
cat > "$CONTEXT_DIR/state.md" << 'EOF'
# Project State

**Project:** [Your Project Name]
**Owner:** [Your Name]
**Branch:** [Branch Name]
**Updated:** $(date +%Y-%m-%d)

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
EOF

echo "✓ Created state.md"

# Create decisions.md
cat > "$CONTEXT_DIR/decisions.md" << 'EOF'
# Architectural Decisions

**Project:** [Your Project Name]
**Updated:** $(date +%Y-%m-%d)

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
EOF

echo "✓ Created decisions.md"

# Create history.md
cat > "$CONTEXT_DIR/history.md" << 'EOF'
# Project History

**Project:** [Your Project Name]
**Started:** $(date +%Y-%m-%d)

## Timeline (Reverse Chronological)

### $(date +%Y-%m-%d) - Project Initialized
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
EOF

echo "✓ Created history.md"

# Create codebase.md
cat > "$CONTEXT_DIR/codebase.md" << 'EOF'
# Codebase Reference

**Project:** [Your Project Name]
**Updated:** $(date +%Y-%m-%d)

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
EOF

echo "✓ Created codebase.md"

# Create guide.md
cat > "$CONTEXT_DIR/guide.md" << 'EOF'
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
EOF

echo "✓ Created guide.md"

# Create MIGRATION.md (for projects migrating from old protocols)
cat > "$CONTEXT_DIR/MIGRATION.md" << 'EOF'
# Migration from Old Context Protocol

**If you're starting fresh, ignore this file.**

This file explains how to migrate from iteration-based JSON protocol to ctx.

## Old → New Mapping

| Old File | New File | Migration Strategy |
|----------|----------|-------------------|
| projectObjectives.md | state.md | Extract current phase, active work, blockers |
| changeLog.md | history.md | Reverse to chronological, keep last 10 iterations |
| README.md | guide.md | Extract navigation, drop metaphors |
| ARCHITECTURE.md | decisions.md | Extract decisions, drop essays |
| plan-*.md | decisions.md | Extract scope as first decision |
| iterationHandoff.md | handoffs/*.md | Preserve as archive |

## Migration Steps

1. **Create new structure** with bootstrap.sh
2. **Extract state** from projectObjectives.md JSON → state.md
3. **Reverse history** from changeLog.md → history.md
4. **Extract decisions** from ARCHITECTURE.md → decisions.md
5. **Map files** from old docs → codebase.md
6. **Archive old files** to .ctx/archive/
7. **Test resilience** by continuing active work

## Philosophy Shift

**Old:** Metaphorical (gifts, handoffs, quantum waves), JSON state machines, iteration ceremony

**New:** Functional, confidence-explicit, staleness-aware, agent-maintained, extensible via kits

**Key Benefits:**
- Less metaphor, more function
- Explicit confidence tracking
- Smaller focused files
- Router system with kits
- Forgiveness as architecture

## Validation

Migration succeeds if:
- ✅ Agent orients in < 5 minutes
- ✅ Non-sequitur tasks don't derail work
- ✅ Confidence levels guide validation priorities
- ✅ Files stay bounded
- ✅ Agent can extend system with kits

---

*After successful migration, move this file to archive/*
EOF

echo "✓ Created MIGRATION.md"

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Next steps:"
echo "1. cd $CONTEXT_DIR"
echo "2. Edit state.md with your project details"
echo "3. Fill in guide.md with project name"
echo "4. Add first decision to decisions.md"
echo ""
echo "Then start working! Update state.md as you go."
echo ""
echo "Run '../ctx/ctx index .' to see your context."
