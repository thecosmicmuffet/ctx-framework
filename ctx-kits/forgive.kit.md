# Kit: forgive

## Purpose
Acknowledge that context has drifted from reality. Reset baseline without shame. Ingest unfulfillment as opportunity for change.

## Philosophical Foundation

**Forgiveness realizes that good faith work may not fulfill requests, and relegates unfulfillment to a state without judgment.**

In practical terms:
- Projects drift - humans get busy, priorities shift, agents lose context
- The cooperative process (trust) must be maintained despite drift
- Forgiveness is not failure - it's **honest acknowledgment** that reality changed
- By forgiving drift, we create space to move forward without epicyclic guilt loops

Forgiveness is architecture for change, not capitulation.

## Behavior Specification

```
./ctx forgive <path|all> [--reason "description"] [--reset-staleness]
```

### Forgive specific file
```
./ctx forgive projectObjectives.md --reason "Raylib project paused for 6 weeks"
```
- Marks file as "drift acknowledged"
- Records reason in forgiveness log
- Optionally resets staleness baseline (treats today as new zero-point)

### Forgive all
```
./ctx forgive all --reason "Major life event, returning to project after hiatus"
```
- Acknowledges drift across entire context
- Useful for "cold opens" after long absence
- Creates forgiveness checkpoint

### With --reset-staleness
Treats current date as new modification baseline:
- File still shows actual last-modified date
- But staleness calculations start from forgiveness date
- Allows working with old content without constant "stale" warnings

## Output Format

```
FORGIVENESS: projectObjectives.md
Reason: Raylib project paused for 6 weeks
Action: Drift acknowledged, staleness baseline reset

Previous state: 48 days stale (2025-10-18)
New baseline: Today (2025-12-06)
Trust level: AGING (reset to medium confidence)

Next steps:
1. Review file contents for what's still valid
2. Update with current reality where needed
3. Run ./ctx trust to verify confidence restored

Forgiveness recorded in .context/.forgiveness-log.json
```

## Storage Structure

```
.context/
├── .forgiveness-log.json
```

### forgiveness-log.json
```json
{
  "forgiveness_events": [
    {
      "date": "2025-12-06T10:30:00Z",
      "scope": "projectObjectives.md",
      "reason": "Raylib project paused for 6 weeks",
      "action": "staleness_reset",
      "agent": "sonnet-4.5",
      "human_acknowledged": false
    },
    {
      "date": "2025-12-06T10:35:00Z",
      "scope": "all",
      "reason": "Major life event, returning to project after hiatus",
      "action": "full_context_forgiveness",
      "agent": "sonnet-4.5",
      "human_acknowledged": true
    }
  ]
}
```

## Implementation Notes

- Forgiveness is **metadata operation**, not content modification
- Does not change actual file modification times
- Creates audit trail of acknowledged drift
- Affects trust calculations: forgiven files get adjusted confidence
- Can be human-initiated or agent-initiated (with different weights)

## Design Principle

**Forgiveness maintains trust by acknowledging reality.** Without forgiveness:
- Agents apologize for stale context endlessly (epicyclic pathology)
- Humans feel guilty about project gaps
- Process grinds down in shame loops
- Trust erodes because "should" diverges from "is"

With forgiveness:
- Drift is factual, not moral
- Baselines can be reset
- Work continues from current reality
- Trust is maintained because honesty is preserved

## Integration with Other Commands

- `trust` → Identifies drift needing forgiveness
- `forgive` → Acknowledges drift, creates opportunity for change
- `honor` → Archives what was learned before moving on

The flow:
1. `trust` reveals stale context
2. `forgive` acknowledges "we drifted, it's okay"
3. Update what's still relevant
4. `honor` what was learned
5. Continue with renewed trust

## To Implement

1. Create `ctx-commands/forgive.ps1`
2. Create `.forgiveness-log.json` structure
3. Integrate with trust calculations
4. Support scope (file, directory, all)
5. Update registry to "implemented"

## Edge Cases

- Forgiving already-forgiven content: Update reason, note repeat forgiveness
- Forgiveness without subsequent updates: Flag after 7 days ("was this helpful?")
- Human vs agent forgiveness: Track separately, human forgiveness has higher weight
