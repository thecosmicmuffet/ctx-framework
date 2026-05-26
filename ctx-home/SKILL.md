---
name: ctx
description: Context navigation framework for home use. Run `ctx chart` to orient, then use ctx commands instead of reading context files directly.
license: MIT
---

# ctx Skill (Home Edition)

ctx is a framework for **personal context continuity**.
It helps an AI-assisted workflow keep its place between sessions, interruptions, and model changes.

## First move: descent

When a new session begins, start with:

```powershell
ctx chart
ctx scent read
```

- **chart** answers: where am I?
- **scent** answers: what recent signals should I know before acting?

If you are inside a registered project, chart resolves to that project.
If not, chart shows the broader home workspace.

## Home model

This edition assumes:

- one person
- one main machine
- local and cloud models working together
- no multi-machine dispatch layer
- no enterprise work queue

The goal is not orchestration across machines.
The goal is **durable personal orientation**.

## Core philosophy

### Vessel / harbor

- **Vessel** = the active context window
- **Harbor** = the persistent context store
- **Chart** = the compact bridge between them

A session arrives empty. The chart helps it re-enter quickly.

### Descent

Descent means moving from uncertainty toward situated work:

1. `ctx chart`
2. `ctx scent read`
3. `ctx state`
4. `ctx todos`
5. act
6. `ctx dock`

### Heartbeat

- **Chart** is the heartbeat.
- **Dock** is the checkpoint.

Use them often. They are cheaper than rebuilding orientation from scratch.

### Commands grow through use

If a command is missing, that is information.
Grow the command from a kit rather than bypassing the framework.

## Runtime layout

ctx keeps durable context in `@ctx/` next to this package after bootstrap.
Typical runtime layout:

```text
ctx-home/
├── SKILL.md
├── ctx.ps1
├── ctx
├── bootstrap.ps1
├── @ctx/
│   ├── registry.json
│   └── projects/
│       └── my-project/
│           ├── chart
│           ├── history.md
│           ├── state.dat
│           ├── todos.json
│           └── decisions.json
├── commands/
├── kits/
└── lib/
```

`@ctx/` is created at runtime by `bootstrap.ps1` or `ctx register`.
It is not part of the distributable package.

## Practice rules

- Use ctx commands for context operations.
- Prefer `ctx chart` over a long orientation ritual.
- Prefer `ctx dock` over waiting until context is overloaded.
- Do not manually edit runtime files if a command exists for the task.

## Suggested session rhythm

```text
chart → work → dock → chart → work → dock
```

## Key commands

- `ctx chart` — compact orientation
- `ctx dock` — checkpoint
- `ctx start` — fuller orientation when needed
- `ctx state` — current project state
- `ctx todos` — pending work
- `ctx decision` — important decisions
- `ctx topic` — expandable topic notes
- `ctx search` — search context
- `ctx trust` — freshness / confidence view
- `ctx session` — named persistent sessions
- `ctx grip` — durable wedge memory
- `ctx pack` / `ctx unpack` — portable context handoff

Remember: **chart is the heartbeat, dock is the checkpoint.**
