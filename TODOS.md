# ctx TODOs

**Current Direction: Commands over file reading. Wedge-style investigation. Information concealment.**

## ✅ Completed (2026-01-07)

### Path Resolution & Core Infrastructure
- [x] Created locate.kit.md - Identity-based path resolution
- [x] Updated ctx.ps1 router - Loads .ctxconfig, expands path variables
- [x] Added augmented headers - Shows git/ctx/cmd status (toggleable with --quiet)
- [x] Environment variables - Commands receive CTX_* vars
- [x] Updated bootstrap.ps1 - Generates .ctxconfig with auto-detection
- [x] Updated commands - index.ps1 and search.ps1 use resolved paths
- [x] Multi-project foundation - Config supports project switching

### Cleanup & Consolidation
- [x] Removed meta-documentation artifacts (CODE-REVIEW-GUIDE, SUMMARY, INDEX, CHANGELOG)
- [x] Consolidated README as single entry point
- [x] Created deterministic command kits - start, state, todos, where

## 📋 High Priority - Deterministic Entry Points

**Goal: Agents invoke commands instead of reading files.**

- [ ] **ctx start** - Entry point (current work, recent history, top todos)
- [ ] **ctx finish** - Complete iteration, update history, optionally archive
- [ ] **ctx continue** - Resume after interruption (pause marker in history)
- [ ] **ctx state** - Show project state (replaces reading state.md)
- [ ] **ctx todos** - Show pending work (replaces reading TODOS.md)
- [ ] **ctx find Symbol** - Find files in codebase (replaces filesystem exploration)
- [ ] **ctx locate** - Full implementation (--show, --set, --list, --init)

These implement iteration lifecycle: `ctx start` → work → `ctx finish --continue-mission`
## 📋 Medium Priority - Core Commands

- [ ] **trust** - Confidence reporting (FRESH/AGING/STALE)
- [ ] **forgive** - Reset baseline with .forgiveness-log.json
- [ ] **honor** - Archive with extracted lessons
- [ ] **contract** - Generate lean agent contracts
- [ ] **summarize** - Multi-depth summaries

## 🧪 Testing & Cross-Platform

- [ ] Test coverage for bootstrap
- [ ] Test coverage for commands  
- [ ] Bash router path resolution (match PowerShell)
- [ ] Cross-platform testing (Linux/macOS)

#### Quality of Life
- [ ] Add command aliases (e.g., `ctx ls` → `ctx index`)
- [ ] Colorize output consistently across platforms
- [ ] Add progress indicators for long operations
- [ ] Support `--help` flag on all commands
- [ ] Add `--version` flag to routers

#### Advanced Features
- [ ] Context diffing between iterations
- [ ] Automatic staleness detection
- [ ] Integration with git hooks
- [ ] VS Code extension for context navigation
- [ ] Context file templates for different project types

## 🐛 Known Issues

### Critical
None identified.

### Non-Critical
1. **Date formatting in bootstrap.sh** - Uses `$(date +%Y-%m-%d)` which may not work on all systems
2. **No input validation** - Bootstrap scripts don't validate directory names
3. **Overwrite prompt** - Could use more safety checks before deleting existing context
 💭 Future Considerations

- Command chaining (e.g., `ctx start | ctx where GroupManagement`)
- Automated dependency property generation (pattern enforcement)
- Symbol/token association for code generation
- Context file consolidation (do we need separate state/history/decisions?)
- .ctx framework improvements for structured data

## 🎯 Design Goals

1. **Information concealment** - Show minimum needed, command-chain for more
2. **Wedge-style investigation** - Narrow focus, not full-context loading
3. **Commands over files** - Agents invoke, never read directly
4. **Deterministic behavior** - Same input = same output
5. **Pattern enforcement** - Simple stable language in kits prevents divergence

## 📝 Philosophy

The system should be a **machine that conceals information**. Critical levers and buttons perform deterministic work. Agents should never spelunk - commands surface exactly what's needed.

When working correctly, most of the framework stays hidden. README is entry point, `ctx start` is first command, everything else reached through command chains.

---

*Last Updated: 2026-01-07