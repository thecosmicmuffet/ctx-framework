# Kit: plan

## Purpose

**Command discovery funnel.** Help agents find relevant ctx commands for planning, decision-making, and context exploration without knowing the full command suite.

## Behavior

```powershell
ctx plan                    # Show available planning commands
ctx plan --help             # Explain wedge-based workflow
```

## Output Example

```
=== CTX PLANNING COMMANDS ===

Review & Triage:
  ctx decision --tag <tag>   # Find architectural decisions by tag
  ctx state                  # Current work, confidence, blockers
  ctx todos                  # Work queue with progress
  ctx codebase find <term>   # Locate files/patterns

Make Progress:
  ctx todos add <title>      # Add work item
  ctx todos complete <id>    # Mark work done
  
Document Decisions:
  (Edit decisions.json directly, then regenerate MD)

Handoff:
  ctx finish                 # Complete iteration, update history

Wedge-Based Workflow:
  1. ctx state               # What's happening?
  2. ctx state --confidence low   # What needs attention?
  3. ctx decision --tag <area>    # Review relevant decisions
  4. ctx codebase --tag <area>    # Find code locations
  5. Work on task
  6. Update JSON files (todos.json, state.json, decisions.json)
```

## Implementation Notes

- **Discovery layer** - agents invoke `ctx plan` when user asks for planning
- Shows relevant commands grouped by purpose
- Explains wedge-based pattern (survey → triage → expand → work)
- Prevents agents from reinventing context tracking

## Design Principle

**Funnel unknown intent to known commands.** User says "let's plan" → agent tries `ctx plan` → sees decision/state/todos/codebase → uses appropriate tool.
