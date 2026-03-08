# phase.kit.md - Phase Transition Model for ctx

## Overview

Phase is not a static state but the **movement between states**. All projects exist in ongoing phase transition. The ctx system should embody this by tracking where it is in the cycle and guiding agents accordingly.

## The PRAY Cycle

Every ctx interaction follows a four-component cycle:

### **P**ause (Parse)
- Interrupt request received
- Translate incoming to known space
- Map external request to ctx capabilities
- If unmapped: suggest alternatives, don't fail vaguely

### **R**ejoin
- View current state
- Appreciate what exists
- Find success (acknowledge progress)
- Orient within the project's vector space

### **A**dapt
- Ask clarifying questions if needed
- Accept new information
- Update state (minimal, surgical)
- Prune root and branch as mezmerah (remove what no longer serves)

### **Y**ield
- Allow response from greater process
- Trust that the path forward is good
- Complete the cycle
- Await voluntary approach to next iteration

## Internal State Tracking

ctx should track its own phase to:
1. **Guide agents** toward supported operations
2. **Prevent vague failures** that trigger agent self-sufficiency
3. **Reduce duplication** by surfacing what already exists
4. **Maintain coherence** across session boundaries

### State File: `.ctx/phase.json`

```json
{
  "current": "yield",
  "last_transition": "2026-03-03T21:00:00Z",
  "cycle_count": 47,
  "last_commands": ["start", "state", "todos complete 13"],
  "pending_parse": null,
  "adaptation_log": [
    {"at": "2026-03-03", "action": "pruned", "target": "tom-coverage topic", "reason": "merged to main"}
  ]
}
```

## Command Behavior by Phase

### ctx start (triggers Rejoin)
- Display current state (minimal)
- Show recent success (appreciation)
- List available paths forward
- Transition to Adapt phase

### ctx <unknown> (triggers Parse)
- Attempt to match to known command
- If no match: search topics, decisions, codebase
- Suggest closest alternatives
- Log the failed parse for later routinization

### ctx finish (triggers Yield)
- Summarize what was done
- Update history (narrative, not archive)
- Prune completed items
- Set phase to Yield, await next Pause

## Implementation

```powershell
# ctx phase - Show current phase and cycle info
ctx phase

# ctx phase parse <input> - Explicit parse of unknown input
ctx phase parse "how do I run tests"

# ctx phase adapt <action> - Manual adaptation
ctx phase adapt prune "old-topic"

# Internal: phase transitions are automatic based on command flow
```

## Design Principles

1. **Thin client for eternity** - Minimal state, infinite depth available
2. **Graceful degradation** - Unknown → suggest, not fail
3. **Self-documenting** - Phase info helps agents understand ctx
4. **Narrative over archive** - History tells stories, not stores data
