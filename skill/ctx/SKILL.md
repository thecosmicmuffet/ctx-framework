---
name: ctx
description: Context navigation framework for agent-maintained context management. Use for project state queries, todo management, architectural decisions, command implementation, and deterministic context operations. Automatically invoked when working with ctx projects.
license: MIT
---

# ctx Skill

You are a specialized agent for working with the **ctx** context navigation system. This framework enables deterministic, command-based context management for agent workflows.

## What Is This Package

This skill is **self-contained**. The `framework/` subdirectory alongside this `SKILL.md` contains everything needed — the router scripts, commands, kits, and libraries. No external clone or install is required.

```
.copilot/skills/ctx/
├── SKILL.md          ← you are here
└── framework/        ← add this directory to PATH
    ├── ctx.ps1       # PowerShell router
    ├── ctx           # Bash router
    ├── bootstrap.ps1 # Initialize a new project's .ctx/ folder
    ├── bootstrap.sh
    ├── registry.json # Command registry (implemented | kit | requested)
    ├── validate.ps1  # Framework self-check (file integrity + bootstrap smoke test)
    ├── commands/     # Runnable command scripts
    ├── kits/         # Build specs for unimplemented commands
    └── lib/          # Shared libraries
```

## Environment Setup

### VS Code / GitHub Copilot (PowerShell)

The skill file is discovered automatically from `.copilot/skills/ctx/SKILL.md`.
Add the framework to PATH so `ctx` can be called directly:

```powershell
# Check if ctx is already in PATH
Get-Command ctx.ps1 -ErrorAction SilentlyContinue

# If not found, add for session:
$env:PATH = "$PWD/.copilot/skills/ctx/framework;$env:PATH"

# Or from any subdirectory (use absolute path):
$skillRoot = (Get-Item "$PSScriptRoot/../../..").FullName  # from framework/ up 3 levels
$env:PATH = (Resolve-Path ".copilot/skills/ctx/framework").Path + ";$env:PATH"
```

### Claude Code (Bash / `.claude/` directory)

Claude Code reads agent instructions from `.claude/`. To install ctx there:

```bash
# Option A: symlink (preferred — single source of truth)
ln -s ../.copilot/skills/ctx .claude/skills/ctx

# Option B: copy framework directly
cp -r .copilot/skills/ctx/framework .claude/skills/ctx/framework

# Add to PATH (bash)
export PATH="$(pwd)/.copilot/skills/ctx/framework:$PATH"
# or if copied to .claude:
export PATH="$(pwd)/.claude/skills/ctx/framework:$PATH"
```

Add the export to your project's `.claude/CLAUDE.md` or `~/.bashrc` so it persists.

### Verify Setup

```bash
# bash
ctx start

# PowerShell
ctx.ps1 start
```

The ctx router walks up the directory tree from `$PWD` to find a `.ctx/` folder, so you can invoke it from any subdirectory of a project.

## Bootstrapping a New Project

Run once from your project root to create the `.ctx/` directory:

```powershell
# PowerShell
.copilot/skills/ctx/framework/bootstrap.ps1

# bash
.copilot/skills/ctx/framework/bootstrap.sh
```

This creates `.ctx/` with `state.json`, `todos.json`, `decisions.json`, `history.md`, and `codebase.json`. Add `.ctx/` to `.gitignore` unless you want to commit project context.

## Core Philosophy

**Commands grow through use. Never bypass routinized operations.**

1. **Three states of territory:**
   - **Unmapped** → Explore (search, read files)
   - **Mapped** → Routinize (implement command from kit)
   - **Routinized** → Execute deterministically (use command)

2. **Read is the on-ramp to execute:**
   - Investigation leads to routinization
   - Rewrite functions to handle new cases
   - Progress toward deterministic execution

3. **Avoid regression:**
   - Every bypass (reading `.ctx` files directly) returns you to unmapped state
   - Use commands, not file reads: `ctx state` not `cat .ctx/state.md`
   - Extend commands when they lack features, don't work around them

## Every Iteration Workflow

### 1. Navigate to Project Directory

```bash
cd /path/to/my-project   # bash
cd C:\path\to\project    # PowerShell
```

### 2. Start Iteration

```bash
ctx start
```

This prints current work, recent history, and pending todos — without reading any files directly.

### 3. Use Commands for Context Operations

**CORRECT — use commands:**
```bash
ctx state          # Query project state
ctx todos          # List pending tasks
ctx decision       # View architectural decisions
ctx search term    # Search .ctx files
ctx topic auth     # Wedge into a topic area
ctx index          # List context files with staleness
```

**INCORRECT — never bypass:**
```bash
# WRONG
cat .ctx/state.md
grep -r "TODO" .ctx/
```

### 4. When a Command Doesn't Exist

```bash
ctx newcommand
# → "Not implemented. Kit exists at: kits/newcommand.kit.md"
```

If a kit exists, implement it:
1. Read the kit: `cat .copilot/skills/ctx/framework/kits/newcommand.kit.md`
2. Create the command: `.copilot/skills/ctx/framework/commands/newcommand.ps1` (and/or `.sh`)
3. Update `registry.json` — change `"status": "kit"` to `"status": "implemented"`
4. Use: `ctx newcommand`

If no kit exists, the command is registered as "requested". Create a kit spec, then implement it.

### 5. Growing Existing Commands

When a command exists but lacks a needed feature, extend it — don't create a new one:

```powershell
# Original: ctx todos (lists todos)
# Need: ctx todos --complete 7

# Extend: edit .copilot/skills/ctx/framework/commands/todos.ps1
# Add handling for --complete flag
```

### 6. Complete Iteration

```bash
ctx finish --continue-mission
```

## Available Commands

### Implemented

| Command | Usage | Purpose |
|---------|-------|---------|
| `start` | `ctx start` | Entry point — current work, history, top todos |
| `state` | `ctx state [--filter <tag>]` | Query project state |
| `todos` | `ctx todos` | List pending tasks |
| `decision` | `ctx decision [--tag <tag>]` | Query architectural decisions |
| `search` | `ctx search <term>` | Wedge-style text search across `.ctx` files |
| `index` | `ctx index` | List context files with sizes and staleness |
| `plan` | `ctx plan` | Command discovery and planning funnel |
| `topic` | `ctx topic <name>` | Progressive context expansion (save-point semantics) |
| `fear` | `ctx fear` | Autonomous loop breakout via project rotation |
| `pack` | `ctx pack` | Create portable handoff archive |
| `unpack` | `ctx unpack [--merge] [--force]` | Restore context from archive |

### Kits (Ready to Implement)

| Command | Kit file | Purpose |
|---------|----------|---------|
| `finish` | `kits/finish.kit.md` | Complete iteration, update history |
| `find` | `kits/find.kit.md` | Find files/symbols in codebase |
| `codebase` | `kits/codebase.kit.md` | Query `codebase.json` location map |
| `locate` | `kits/locate.kit.md` | Project identity / git root resolution |
| `trust` | `kits/trust.kit.md` | Report FRESH/AGING/STALE confidence levels |
| `summarize` | `kits/summarize.kit.md` | Agent-maintained summaries at varying depth |
| `forgive` | `kits/forgive.kit.md` | Reset baseline without shame |
| `honor` | `kits/honor.kit.md` | Archive with extracted lessons |
| `contract` | `kits/contract.kit.md` | Generate lean agent contracts |
| `phase` | `kits/phase.kit.md` | PRAY cycle state tracking |
| `narrative` | `kits/narrative.kit.md` | History as story, not archive |

### Command Disambiguation

- `find` — searches the **codebase** map (`codebase.json`) for files/symbols
- `search` — searches **.ctx text files** for a term
- `locate` — determines **project identity** (which repo/clone/branch you are in)
- `topic` — **progressive expansion** into a knowledge area, with save-point semantics

## Implementation Guidelines

### Creating a Command from a Kit

1. **Read the kit** (paths use `/` throughout; use `\` on Windows PowerShell):
   ```bash
   cat .copilot/skills/ctx/framework/kits/<commandname>.kit.md
   ```

2. **Create the implementation:**
   - PowerShell: `.copilot/skills/ctx/framework/commands/<commandname>.ps1`
     - Begin with `#!/usr/bin/env pwsh`
     - Accept `[Parameter(ValueFromRemainingArguments)]` for flags
   - Bash: `.copilot/skills/ctx/framework/commands/<commandname>.sh`
     - Begin with `#!/usr/bin/env bash`
   - Exit 0 on success; non-zero on error

3. **Update registry** — `.copilot/skills/ctx/framework/registry.json`:
   ```json
   "<commandname>": {
     "status": "implemented",
     "description": "Brief description",
     "implemented": "YYYY-MM-DD",
     "added_by": "agent-name"
   }
   ```

4. **Test:**
   ```bash
   ctx <commandname>
   ```

### Extending Existing Commands

Grow commands rather than creating new ones:

```powershell
# Need: ctx todos --complete <id>
# Edit: .copilot/skills/ctx/framework/commands/todos.ps1
# Add parameter handling for --complete, then use: ctx todos --complete 7
```

## Anti-Patterns

### ❌ Bypassing Commands
```bash
# WRONG
cat .ctx/state.md
grep "TODO" .ctx/TODOS.md

# RIGHT
ctx state
ctx todos
```

### ❌ Creating Duplicate Commands
```
WRONG: creating todos-complete.ps1
RIGHT: extend todos.ps1 to handle --complete
```

### ❌ Hardcoding Absolute Paths
```powershell
# WRONG
$state = Get-Content "C:\Users\me\project\.ctx\state.md"

# RIGHT — ctx router walks up tree to find .ctx
ctx state
```

### ❌ Referencing Old Locations
The framework was previously expected at `scripts/ctx/` or `D:\skite.Tools\projects\ctx`.
Those locations are obsolete. The canonical location is `.copilot/skills/ctx/framework/`
(or `.claude/skills/ctx/framework/` for Claude Code installs).

## Troubleshooting

### `ctx` Not Found

```powershell
# PowerShell — add to PATH for current session
$env:PATH = (Resolve-Path ".copilot/skills/ctx/framework").Path + ";$env:PATH"
Get-Command ctx.ps1   # verify
```

```bash
# bash — add to PATH for current session
export PATH="$(pwd)/.copilot/skills/ctx/framework:$PATH"
which ctx             # verify
```

### Command Not Found in Registry

```bash
# Inspect the registry
cat .copilot/skills/ctx/framework/registry.json

# Check if a kit exists for it
ls .copilot/skills/ctx/framework/kits/
```

If a kit exists, implement it. If not, run `ctx <commandname>` once — it will be auto-registered as "requested".

### Execution Policy (PowerShell)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Command Returns Kit Instructions
```
ctx finish
# → "Not implemented. Kit exists: kits/finish.kit.md"
```
This is expected. Read the kit, implement the command, update registry, then use it.

## Example Workflows

### Starting a Work Session

```bash
cd /path/to/my-project
ctx start
ctx state --filter active
ctx todos
```

### Implementing a Missing Command

```bash
# 1. Try it (see what feedback you get)
ctx finish

# 2. Read the kit
cat .copilot/skills/ctx/framework/kits/finish.kit.md

# 3. Create the implementation
# .copilot/skills/ctx/framework/commands/finish.ps1  (and/or finish.sh)

# 4. Update registry.json: "status": "implemented"

# 5. Test
ctx finish --continue-mission
```

### Wedge-Style Investigation

```bash
ctx search authentication        # Find mentions in .ctx files
ctx decision --tag authentication # Why auth works the way it does
ctx topic auth                    # Progressive expansion into auth area
ctx state --filter security       # Security-tagged work items
```

## Success Criteria

You're using ctx correctly when:

- ✅ Every iteration starts with `ctx start`
- ✅ Context queries use commands, not file reads
- ✅ Missing commands get implemented from kits
- ✅ Existing commands grow to handle new cases
- ✅ No bypassing with grep/cat for `.ctx` files
- ✅ Command implementations follow kit specifications
- ✅ Operations progress toward routinized execution

## References

All paths below are relative to the directory where this skill package is installed.

- Skill file: `.copilot/skills/ctx/SKILL.md`
- Framework: `.copilot/skills/ctx/framework/`
- Router (PowerShell): `.copilot/skills/ctx/framework/ctx.ps1`
- Router (bash): `.copilot/skills/ctx/framework/ctx`
- Command registry: `.copilot/skills/ctx/framework/registry.json`
- Command implementations: `.copilot/skills/ctx/framework/commands/`
- Kit specifications: `.copilot/skills/ctx/framework/kits/`
- Bootstrap: `.copilot/skills/ctx/framework/bootstrap.ps1` / `bootstrap.sh`

For Claude Code installs, substitute `.copilot/` with `.claude/` in all paths above.

---

**Remember:** Commands are tokens that execute and grow. Investigate → Routinize → Execute. Never bypass. Always extend.
