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
