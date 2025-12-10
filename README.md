# ctx - Context Navigation Framework

A bootstrapping toolkit for agent-maintained context management.

## Philosophy

This framework teaches itself through use. Commands that don't exist yet return instructions for building them. Agents extend the system by implementing what they need. Humans intervene at environment boundaries.

**The goal:** Make "starting from scratch" a dignified path. Assume staleness. Treat handoffs as gifts, not contracts. Track confidence decay explicitly.

## Structure

```
ctx                     # Router script
ctx-registry.json       # Command registry (status: implemented|kit|requested)
ctx-commands/           # Implemented commands (.sh scripts)
ctx-kits/               # Build instructions for unimplemented commands
```

## Usage

```bash
./ctx                   # Show available commands
./ctx index             # List context files with sizes/staleness
./ctx search term       # (kit available) Wedge-style search
./ctx anything          # Request a new command
```

## Command Lifecycle

1. **Unknown** → Agent tries `./ctx foo`, system registers as "requested"
2. **Kit** → Agent or human creates `ctx-kits/foo.kit.md` with build spec
3. **Implemented** → Agent creates `ctx-commands/foo.sh`, marks implemented

## Current Commands

| Command | Status | Description |
|---------|--------|-------------|
| index | implemented | List files with sizes, dates, staleness |
| search | kit | Wedge-style term search with expansion |
| summarize | kit | Agent-maintained summaries at varying depth |
| trust | requested | Report confidence and stale regions |
| forgive | requested | Reset baseline without shame |
| honor | requested | Mark as learned-from, now resting |

## Installation

Copy this folder to your project as `scripts/ctx/` or similar. Make `ctx` executable:

```bash
chmod +x ctx ctx-commands/*.sh
```

## Extending

To add a command:

1. Create `ctx-commands/yourcommand.sh`
2. Update `ctx-registry.json` with status "implemented"

To propose a command:

1. Create `ctx-kits/yourcommand.kit.md` with spec
2. Update `ctx-registry.json` with status "kit"

## Disposal

This framework is designed to become unnecessary. When better tooling makes it obsolete, run:

```bash
./ctx honor .
```

Then archive the folder with a note about what was learned.

## What Was Learned Here

- Bounded files (~200 lines) prevent token overflow
- Paths not taken stabilize decisions
- Forgiveness is architecture, not sentiment
- Agents can maintain their own institutional memory
- The absence of a command can be instructive

---

*Version: 0.1.0 | Created: 2025-12-06 | Status: Bootstrap*
