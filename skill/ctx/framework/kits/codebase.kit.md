# Kit: codebase

## Purpose

**Map WHERE things are in codebase via structured JSON.** Find files, patterns, and search hints without filesystem exploration.

## Behavior

```powershell
ctx codebase find <term>           # Find entries matching term
ctx codebase --tag tiles           # Filter by tag
ctx codebase --tag duplication     # Find duplication patterns
ctx codebase --type pattern        # Show architectural patterns only
ctx codebase --type files          # Show file locations only
```

## Data Structure (codebase.json)

```json
{
  "entries": [
    {
      "id": "viewmodel-provider-startmenu",
      "type": "pattern",
      "tags": ["viewmodel", "singleton", "startmenu", "provider"],
      "title": "ViewModelProvider (StartMenu)",
      "location": "StartMenu/lib/ViewModelProvider.h",
      "description": "Singleton provider for all ViewModels via static methods",
      "example": "ViewModelProvider::AllApps()",
      "related": ["viewmodel-provider-start"],
      "search_hints": ["ViewModelProvider::", "static.*ViewModel"]
    },
    {
      "id": "tile-viewmodels-startmenu",
      "type": "files",
      "tags": ["tile", "viewmodel", "startmenu", "duplication"],
      "title": "Tile ViewModels (StartMenu)",
      "files": [
        "AllAppsTileViewModel.h",
        "AllAppsSuiteTileViewModel.h",
        "PinnedListTileViewModel.h"
      ],
      "location": "StartMenu/lib/",
      "pattern": "Duplicate launch/context-menu logic across 3+ VMs",
      "related": ["unified-tile-vm"]
    },
    {
      "id": "start-projects",
      "type": "structure",
      "tags": ["start", "projects", "architecture"],
      "title": "Start Project Structure",
      "description": "Three-project architecture for migration",
      "entries": [
        {
          "path": "Start/Start",
          "role": "Hedge project (1:1 migration for testing)"
        },
        {
          "path": "Start/StartViewModel", 
          "role": "Shared ViewModel/Model layer"
        },
        {
          "path": "Start/Stwoart",
          "role": "New view with custom controls"
        }
      ]
    }
  ]
}
```

## Implementation Notes

- **codebase.json** = source of truth (structured, queryable)
- **codebase.md** = auto-generated view (optional)
- Entry types: pattern, files, structure, dependency
- Tags enable filtering by concern (tiles, duplication, viewmodel, etc.)
- Related field links to decision IDs or other codebase entries
- Search hints guide grep/semantic search

## Usage Pattern

**Instead of reading codebase.md or exploring filesystem:**
```powershell
# Bad (old way)
Get-Content .ctx/codebase.md   # Read everything
file_search "**/*ViewModel*.h"      # Blind search

# Good (wedge-based)
ctx codebase --tag tiles            # Find tile-related code
ctx codebase find ViewModelProvider # Targeted search
ctx codebase --tag duplication      # Find known duplication
```

## Design Principle

**Curated map, not filesystem dump.** Only track architecturally significant locations. Tags enable triage. Search hints guide deep dives when needed.
