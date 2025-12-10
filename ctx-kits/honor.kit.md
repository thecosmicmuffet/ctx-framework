# Kit: honor

## Purpose
Mark something as learned-from, now resting. Uses intent behind requests to reconcile forgiveness and trust without epicyclic processes.

## Philosophical Foundation

**Honor reconciles trust and forgiveness by recognizing when we've extracted the value and can move forward.**

The problem honor solves:
- Trust says "follow the plan"
- Forgiveness says "the plan drifted, that's okay"
- But neither says **"the plan taught us what we needed; we can let it rest now"**

Without honor:
- Dead plans accumulate, creating guilt
- Old documentation clutters navigation
- "Should we still do this?" loops waste energy
- Process gets stuck in local minimum of abandoned half-done work

With honor:
- Extract lessons from incomplete work
- Archive with gratitude, not shame
- Intent is preserved even when execution changed
- Process grows beyond limitations in original requests

## Behavior Specification

```
./ctx honor <path> --lesson "what was learned" [--archive]
```

### Honor a plan
```
./ctx honor plan-raylib-bootstrap.md --lesson "Shader-first architecture proven viable, hot-reload pattern established" --archive
```
- Records what was learned
- Marks plan as "honored" (not active, not abandoned)
- Optionally moves to `.context/honored/` archive

### Honor a file/directory
```
./ctx honor handoffs/2025-10-*.md --lesson "Iteration pattern refined, learned importance of bounded context"
```
- Bulk honor for related files
- Captures collective lesson
- Preserves intent without requiring completion

### Honor entire framework (disposal)
```
./ctx honor . --lesson "Context management framework fully internalized into workflow"
```
- From README: "This framework is designed to become unnecessary"
- When better tooling makes it obsolete, honor it
- Archive with gratitude for what it taught

## Output Format

```
HONOR: plan-raylib-bootstrap.md

Lesson learned:
  "Shader-first architecture proven viable through hot-reload pattern.
   Demonstrated value of starting lo-fi and upgrading later. Pattern
   now understood and can guide future work without this specific plan."

Status: HONORED
Original intent: ✓ Achieved (via different path than planned)
Completion: 4/6 steps (66%)
Created: 2025-10-17 (49 days ago)
Honored: 2025-12-06 (by sonnet-4.5)

Archive action: Moved to .context/honored/plans/
  → plan-raylib-bootstrap.md
  → plan-raylib-bootstrap.lessons.md (extracted)

This plan can now rest. Its wisdom lives on in:
  - ARCHITECTURE.md (AD-001: Shader-first rendering)
  - Current project patterns
  - Your understanding

Run './ctx search shader-first' to see how this lesson propagated.
```

## Storage Structure

```
.context/
├── honored/
│   ├── plans/
│   │   ├── plan-raylib-bootstrap.md
│   │   └── plan-raylib-bootstrap.lessons.md
│   ├── handoffs/
│   │   └── 2025-10-iteration-series.lessons.md
│   └── honor-registry.json
```

### honor-registry.json
```json
{
  "honored_items": [
    {
      "path": "plan-raylib-bootstrap.md",
      "honored_date": "2025-12-06T11:00:00Z",
      "lesson": "Shader-first architecture proven viable...",
      "original_intent": "achieved_alternate_path",
      "completion_level": 0.66,
      "propagated_to": [
        "ARCHITECTURE.md#AD-001",
        "games/shader-triangle/",
        "agent understanding"
      ],
      "archived_to": "honored/plans/",
      "honored_by": "sonnet-4.5",
      "human_acknowledged": true
    }
  ]
}
```

## Implementation Notes

- Honor is **culmination operation** - end of a context arc
- Extracts lessons explicitly (agents write .lessons.md files)
- Creates closure without requiring 100% completion
- Archives with metadata about intent and outcome
- Reduces active context by moving to `honored/`

## Design Principle

**Honor uses intent as the guidepost.** This prevents:
- Abandoning work without learning from it
- Guilt over incomplete plans
- Accumulating zombie documentation
- Getting stuck in "but we said we'd do X" loops

Intent-based evaluation asks:
- *What did we want to achieve?* (the telos)
- *Did we solve the underlying problem?* (possibly differently)
- *What did we learn along the way?* (the value)
- *Can this now rest?* (closure)

If yes → honor it, archive the lesson, move forward unburdened.

## Integration with Other Commands

Complete lifecycle:
1. `trust` - Start work assuming instructions will be followed
2. Work proceeds, drift happens
3. `forgive` - Acknowledge drift without judgment
4. Continue or pivot based on lessons
5. `honor` - Extract lesson, archive with gratitude
6. `trust` renewed for next cycle

Honor prevents pathological loops:
- Not abandoned (shame)
- Not active (guilt)
- **Honored** (gratitude + lessons preserved)

## To Implement

1. Create `ctx-commands/honor.ps1`
2. Create `honored/` directory structure
3. Implement lesson extraction (agent writes it)
4. Create honor-registry.json
5. Support archival workflow
6. Update registry to "implemented"

## Special Case: Framework Self-Disposal

From README:
> "This framework is designed to become unnecessary. When better tooling makes it obsolete, run: `./ctx honor .`"

The ultimate honor: when ctx-framework itself has taught you what you needed and can be archived. The commands themselves become training wheels you no longer need.

## Edge Cases

- Honoring active work: Prompt "are you sure? this is still marked active"
- Honoring without lessons: Require `--lesson` flag (force extraction of value)
- Re-honoring: Note that it was already honored, allow updating lesson
- Human vs agent honor: Track both, human honor closes the loop definitively
