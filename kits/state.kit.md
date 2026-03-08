# Kit: state

## Purpose

**Query project state via structured JSON.** Wedge-based exploration - get only what you need without reading full files.

## Behavior

```powershell
ctx state                      # Summary: phase, active work, confidence counts
ctx state --tag tiles          # Filter work items by tag
ctx state --confidence low     # Show low-confidence areas needing attention
ctx state --status blocked     # Show blocked items
ctx state --blockers           # All items with blockers
```

## Data Structure (state.json)

```json
{
  "phase": "Implementation - Phase 1",
  "updated": "2026-01-09",
  "work_items": [
    {
      "id": "analyze-tile-vms",
      "status": "active",
      "title": "Analyze Tile ViewModels",
      "tags": ["analysis", "tiles", "viewmodel"],
      "confidence": "medium",
      "blockers": []
    }
  ],
  "confidence": {
    "high": [{"id": "...", "description": "..."}],
    "medium": [...],
    "low": [...]
  }
}
```

## Implementation Notes

- **state.json** = source of truth (structured, queryable)
- **state.md** = auto-generated view (human-readable, optional)
- Filter by: tags, confidence, status (active/next/blocked/completed)
- Work items track: id, title, tags, confidence, blockers
- Confidence areas track knowledge gaps

## Design Principle

**Wedge-based investigation**: Query tags/filters to get only relevant context. Never read full files. Update JSON directly, regenerate MD.
