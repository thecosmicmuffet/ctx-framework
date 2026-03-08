# Kit: finish

## Purpose

**Complete an iteration and prepare for handoff.** Records what was accomplished, updates confidence levels, archives if needed. Iteration = from `ctx start` to `ctx finish`, not AI session boundary.

## Terminology

- **Agent**: Human or AI contributor
- **Iteration**: Complete work cycle (may span multiple AI sessions)
- **Mission**: Long-term objective (may span multiple iterations)
- **Process**: The larger corporate/economic work we contribute to

## Behavior

```bash
ctx finish [--archive] [--continue-mission]
```

**Default (mission complete):**
1. Summarize iteration work
2. Update history.md with completed iteration
3. Move current work from state.md to history
4. Archive to handoffs/ with timestamp
5. Mark mission complete in state.md

**With --continue-mission:**
1. Summarize iteration work  
2. Update history.md
3. Update state.md "Next" section for next iteration
4. DO NOT archive - mission continues

**Output:**
```
ITERATION COMPLETE
==================
Duration: ctx start (2026-01-07 14:30) → ctx finish (2026-01-07 18:45)
Iteration: 4

Completed:
  ✓ Path resolution system implemented
  ✓ Disambiguated find/search/locate
  ✓ Cleaned up meta-documentation

Mission Status: CONTINUING (CustomizableCategories)
Next Iteration Focus: Implement ctx start command

Archived: No (--continue-mission)
History updated: scripts/.ctx/history.md
```

## Mission vs Iteration

**Mission** = "Implement CustomizableCategories feature" (weeks/months)
**Iteration** = "Design path resolution system" (hours/days)

Iterations nest within missions. Interruptions (bug fixes) are separate mini-missions.

## Design Principle

Iterations are for agents (both types). They mark natural breakpoints where context can be handed off, archived, or continued with fresh perspective.

## To Implement

1. Parse current state.md for iteration info
2. Summarize changes since `ctx start`
3. Update history.md with completed work
4. Optional archive to handoffs/YYYY-MM-DD-iteration-N.md
5. Prepare state.md for next iteration or mark complete
