# ctx - Context Navigation Framework

A bootstrapping toolkit for agent-maintained context management.

## Philosophy

This framework teaches itself through use. Commands that don't exist yet return instructions for building them. Agents extend the system by implementing what they need. Humans intervene at environment boundaries.

**The goal:** Make "starting from scratch" a dignified path. Assume staleness. Treat handoffs as gifts, not contracts. Track confidence decay explicitly.

## Structure

```
ctx                     # Router script (Bash - primary)
ctx.ps1                 # Router script (PowerShell - fallback)
ctx-registry.json       # Command registry (status: implemented|kit|requested)
ctx-commands/           # Implemented commands (.sh scripts, .ps1 fallbacks)
ctx-kits/               # Build instructions for unimplemented commands
```

## Usage

```bash
./ctx                   # Show available commands
./ctx trust             # Report confidence levels and staleness
./ctx index             # List context files with sizes
./ctx search term       # Search across context files
./ctx fear invoke proj  # Invoke fear rotation for stuck context
```

**Note:** Commands are implemented as `.sh` (Bash) scripts. The router checks for `.sh` first, then falls back to `.ps1` (PowerShell) if needed. Works on Windows (Git Bash/WSL), macOS, and Linux.

## Command Lifecycle

1. **Unknown** → Agent requests command, system registers as "requested"
2. **Kit** → Agent or human creates `ctx-kits/foo.kit.md` with build spec
3. **Implemented** → Agent creates `ctx-commands/foo.sh`, marks implemented in registry

## Current Commands

| Command | Status | Description |
|---------|--------|-------------|
| index | implemented | List files with sizes, dates, staleness |
| search | implemented | Wedge-style term search with expansion |
| trust | implemented | Report confidence and stale regions |
| fear | implemented | Context rotation when path forward unclear |
| summarize | kit | Agent-maintained summaries at varying depth |
| forgive | kit | Reset baseline without shame |
| honor | kit | Mark as learned-from, now resting |

## Installation

**Windows:**
The framework is ready to use. No installation needed. PowerShell scripts run with `-ExecutionPolicy Bypass`.

**Unix/Linux/macOS:**
Make bash scripts executable:
```bash
chmod +x ctx ctx-commands/*.sh
```

## Extending

To add a command:

1. Create `ctx-commands/yourcommand.sh`
2. Update `ctx-registry.json` with status "implemented"

To propose a command:

1. Create `ctx-kits/yourcommand.kit.md` with build spec
2. Update `ctx-registry.json` with status "kit"

## Disposal

This framework is designed to become unnecessary. When better tooling makes it obsolete, run:

```bash
./ctx honor .
```

Then archive the folder with a note about what was learned.

## Special Commands

### Fear - Context Rotation for Uncertainty

When the path forward becomes unclear—iteration spirals, assumptions destabilize, or confidence diverges—the **fear** command enables context rotation.

```bash
./ctx fear invoke <project>   # Snapshot and analyze impediment
./ctx fear assess              # Evaluate queue health
./ctx fear liturgy <id>        # Display grounding phrase
```

See [.context/fear/README.md](../.context/fear/README.md) for full documentation.

**Philosophy:** Fear is the felt experience of being more than you appear. When stuck, rotate perspective—approach from the other side. The ratchet advances through rotation, not repetition.

## What Was Learned Here

- Bounded files (~200 lines) prevent token overflow
- Paths not taken stabilize decisions
- Forgiveness is architecture, not sentiment
- Agents can maintain their own institutional memory
- The absence of a command can be instructive
- Fear rotation prevents spiral - uncertainty is navigable
- Bash-first approach aligns with agent tools and cross-platform usage
- PowerShell fallback maintains Windows-only compatibility if needed

---

*Version: 0.3.0 | Created: 2025-12-06 | Updated: 2026-01-04 | Status: Bash Primary, Cross-Platform*
