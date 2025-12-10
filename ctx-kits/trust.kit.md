# Kit: trust

## Purpose
Report on the trustworthiness of context - can instructions and requests be fulfilled based on current state? Foundation for cooperative agent-human work.

## Philosophical Foundation

**Trust is the assumption that instructions will be followed and that both parties demonstrate good faith work.** In the context framework, trust means:
- Assuming documented state reflects reality until proven otherwise
- Taking responsibility to validate assumptions when they matter
- Working in good faith even when context is stale
- Reporting honestly when trust cannot be maintained

Trust is not blind faith - it's a **resilient cooperative strategy** that assumes the best while acknowledging uncertainty.

## Behavior Specification

```
./ctx trust [file|all] [--verbose]
```

### Default behavior (trust all)
Reports confidence levels across all context:
- **Fresh** (0-7 days): High confidence, use directly
- **Aging** (7-30 days): Medium confidence, validate if critical
- **Stale** (30+ days): Low confidence, verify before acting
- **Marked questionable**: Agent or human flagged as suspect

### Specific file
```
./ctx trust projectObjectives.md
```
Reports:
- Last modified date
- Staleness indicator
- Known inconsistencies (if any)
- Confidence level for using this file to guide work

### With --verbose
Additional context:
- What would increase trust (validation steps)
- Related files that might contradict
- Suggested verification commands

## Output Format

```
TRUST REPORT: .context/

FRESH (high confidence - use directly)
  changeLog.md              2 days old

AGING (medium confidence - validate if critical)
  README.md                12 days old
  ARCHITECTURE.md          15 days old

STALE (low confidence - verify before acting)
  projectObjectives.md     48 days old
  plan-raylib-bootstrap.md 49 days old

MARKED QUESTIONABLE
  (none)

======================================================================
Overall confidence: MEDIUM
Recommendation: Review stale files before making architectural decisions.
Consider running: ./ctx forgive . --acknowledge-drift
```

## Implementation Notes

- Staleness thresholds should be configurable
- Trust levels inform how agents use context:
  - **Fresh**: Quote directly, assume accurate
  - **Aging**: Use cautiously, note age when referencing
  - **Stale**: Treat as historical, verify before acting
- The command itself is **descriptive not prescriptive** - reports reality

## Design Principle

**Trust assumes cooperation.** The best outcome occurs when all parts of the process follow good faith principles. This command helps maintain that by:
1. Making uncertainty visible
2. Avoiding false confidence in stale data
3. Supporting honest evaluation without judgment
4. Enabling agents to self-assess their foundation

## Integration with Other Commands

- `trust` → Identifies stale regions
- `forgive` → Resets baseline acknowledging drift
- `honor` → Marks what was learned before archiving

## To Implement

1. Create `ctx-commands/trust.ps1`
2. Read file modification times from index data
3. Apply staleness rules (configurable thresholds)
4. Support per-file trust queries
5. Update registry to "implemented"

## Edge Cases

- Binary files: Skip, trust only applies to readable context
- Files marked with special metadata (`.trust-override`): Respect manual trust levels
- Empty context: Report "no context to evaluate"
