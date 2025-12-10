# Kit: summarize

## Purpose
Generate, retrieve, or update agent-maintained summaries of context files. Summaries exist at multiple depths to support wedge-style investigation.

## Behavior Specification

```
./ctx summarize <file|all> [--depth brief|standard|deep] [--refresh]
```

### Modes

**Retrieve existing summary:**
```
./ctx summarize projectObjectives.md
```
Returns cached summary if fresh, or note that refresh needed.

**Generate/refresh summary:**
```
./ctx summarize projectObjectives.md --refresh
```
Agent generates new summary, stores in `.context/.summaries/`

**All files:**
```
./ctx summarize all --depth brief
```
Returns brief summaries of all context files.

## Depth Levels

### brief (1-2 sentences)
- What is this file?
- Current status/phase if applicable

### standard (1 paragraph, default)
- Purpose and scope
- Key current state
- Notable blockers or decisions

### deep (detailed, up to 20 lines)
- Full context extraction
- All active items
- Historical notes if relevant

## Storage Structure

```
.context/
├── .summaries/
│   ├── manifest.json           # Tracks freshness
│   ├── projectObjectives.brief.md
│   ├── projectObjectives.standard.md
│   ├── changeLog.brief.md
│   └── ...
```

### manifest.json
```json
{
  "projectObjectives.md": {
    "source_modified": "2025-12-06T10:00:00Z",
    "summaries": {
      "brief": {
        "generated": "2025-12-06T10:05:00Z",
        "stale": false
      },
      "standard": {
        "generated": "2025-12-06T10:05:00Z", 
        "stale": false
      }
    }
  }
}
```

## Freshness Logic

Summary is **stale** if:
- Source file modified after summary generated
- Summary older than 7 days (configurable)
- Marked stale by `./ctx forgive`

## Output Format

```
SUMMARY: projectObjectives.md (standard)
Generated: 2025-12-06 (fresh)

Machine-readable project state tracking customizable categories
feature. Currently in Phase 1 (Data Layer Foundation), working on 
UserCategory struct definition. No active blockers. Behind 
Feature_Start5point1 velocity key.

---
Source: 187 lines | Summary: 4 lines (98% reduction)
```

## Implementation Notes

- Summaries are written BY AGENTS, not auto-generated
- The script manages storage/retrieval; agent provides content
- `--refresh` should prompt: "Provide summary for [file] at [depth] level:"
- Or accept piped input: `echo "summary text" | ./ctx summarize file.md --refresh`

## Agent Workflow

1. Agent runs `./ctx summarize projectObjectives.md`
2. Script returns existing summary OR "No summary exists. Run with --refresh to create."
3. Agent runs `./ctx summarize projectObjectives.md --refresh`
4. Script prompts for summary text
5. Agent provides summary
6. Script stores and confirms

## To Implement

1. Create `ctx-commands/summarize.ps1`
2. Create `.summaries/` directory structure
3. Implement manifest tracking
4. Update registry status to "implemented"

## Design Principle

Summaries are **institutional memory maintained by agents**. They represent an agent's understanding, not mechanical extraction. This is why agents write them, not algorithms.
