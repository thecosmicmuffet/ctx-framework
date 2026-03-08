# Kit: continue

## Purpose

**Continue work within current iteration after interruption.** For when you pause (investigate bug, context window full) but iteration isn't complete.

## Behavior

```bash
ctx continue [--note "Investigated X, returning to Y"]
```

Records the interruption in history without finishing iteration. Updates state.md to reflect resumption.

## Design Principle

Interruptions happen. Don't force iteration completion for every context window refresh. Continue preserves iteration identity while acknowledging the pause.

## To Implement

Add pause/resume markers to history without incrementing iteration count.
