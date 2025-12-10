# Kit: search

## Purpose
Wedge-style term search across context files. Returns matches with surrounding context and expansion hints pointing to related content.

## Behavior Specification

```
./ctx search <term> [--depth N] [--expand]
```

### Default behavior
1. Search all files in .context/ for `<term>`
2. Return matches with 2 lines of context above/below
3. Show file path, line number, match preview
4. Sort by relevance (exact match > partial > related)

### With --depth N
Control context lines (default 2, max 10)

### With --expand  
After showing matches, suggest related terms found near matches:
"Also found nearby: [term1], [term2], [term3]"

## Output Format

```
SEARCH: "category" in .context/

projectObjectives.md:47
  45│   "activeStep": {
  46│     "step": "Phase 1 - Task 1",
> 47│     "objective": "Define UserCategory data structure",
  48│     "actions": [

changeLog.md:23
  21│   "changes": [
  22│     {
> 23│       "scope": "category-provider",
  24│       "description": "Added category CRUD"

Found 2 matches in 2 files.
Nearby terms: [UserCategory, CategoryProvider, CRUD, provider]
```

## Implementation Notes

- Use Select-String for basic matching
- Consider case-insensitive by default, --case for sensitive
- For "nearby terms": extract identifiers within ±5 lines of match
- Keep output under 50 lines unless --full specified
- Return exit code 0 if matches, 1 if none

## Edge Cases
- Binary files: skip with note
- Very long lines: truncate at 120 chars with "..."
- Many matches in one file: show first 3, note "and N more"

## To Implement

1. Create `ctx-commands/search.ps1` with above behavior
2. Update `ctx-registry.json`: change status from "kit" to "implemented"
3. Test with: `./ctx search test`

## Stretch Goals (future kits)
- `search --json` for machine-readable output
- `search --files-only` just list matching files
- Integration with summarize (search in summaries first)
