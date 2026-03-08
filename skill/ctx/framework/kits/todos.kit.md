# Kit: todos

## Purpose

**Show pending work without reading TODOS.md directly.** Eventually could consolidate with state.md "Next" section.

## Behavior

```bash
ctx todos              # Show all pending work
ctx todos --high       # High priority only
ctx todos --add "Task" # Add new todo
```

## Design Principle

Todos accessible via command, not file reading. Could replace TODOS.md entirely, storing in state.md or separate tracked file.
