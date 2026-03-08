# Kit: decision

## Purpose

**Query architectural decisions via structured JSON.** Wedge-based exploration - filter by tag/status/confidence to find relevant decisions without reading everything.

## Behavior

```powershell
ctx decision                          # List all decisions (summary)
ctx decision <id>                     # Show specific decision details
ctx decision --tag tiles              # Filter decisions by tag
ctx decision --tag consolidation      # Find consolidation-related decisions
ctx decision --status accepted        # Show only accepted decisions
ctx decision --confidence high        # Filter by confidence level
ctx decision --list                   # Brief list view
```

## Data Structure (decisions.json)

```json
{
  "decisions": [
    {
      "id": "unified-tile-vm",
      "title": "Unified TileViewModel Architecture",
      "date": "2026-01-08",
      "status": "accepted",
      "tags": ["viewmodel", "consolidation", "tiles", "architecture"],
      "context": "StartMenu has 3+ separate Tile VMs that duplicate logic...",
      "decision": "Create single unified TileViewModel...",
      "design": "TileViewModel wraps UTM, provides launch/context/display...",
      "alternatives": [
        {
          "option": "Keep separate VMs",
          "rejected": "Duplication"
        }
      ],
      "rationale": "Tiles are fundamentally same regardless of surface...",
      "consequences": {
        "positive": ["DRY", "Consistent behavior", "Single fix location"],
        "negative": ["Careful design needed", "Conditional logic for edges"]
      },
      "confidence": "high",
      "related": ["unified-container-vm", "surface-provider-pattern"]
    }
  ]
}
```

## Implementation Notes

- **decisions.json** = source of truth (structured, queryable, tagged)
- **decisions.md** = auto-generated view (human-readable, optional)
- Each decision has unique ID for reference
- Tags enable wedge-based filtering (only see relevant decisions)
- Related field links decisions together
- Status: proposed, accepted, deprecated, rejected
- Confidence: high, medium, low

## Usage Pattern

**Instead of reading decisions.md:**
```powershell
# Bad (old way)
Get-Content .ctx/decisions.md  # Reads everything

# Good (wedge-based)
ctx decision --tag tiles            # Only tile-related decisions
ctx decision unified-tile-vm        # Specific decision details
```

## Design Principle

**Wedge-based investigation**: Start narrow (tags), expand relevant nodes (IDs), never load full context. Tags prevent re-triage. Related fields guide exploration.
