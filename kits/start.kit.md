# Kit: start

## Purpose

**Deterministic entry point for agents beginning work.** Surfaces essential information without file exploration.

## Behavior

```bash
ctx start
```

Shows: Project identity, current work (from state.md), recent history, top todos, confidence level.

## Design Principle

**Information concealment.** Show minimum needed to begin. Command-chain for more detail.

Chain example:
```bash
ctx start           # Overview
ctx state --full    # More detail
ctx where Symbol    # Find file
```

README says: "Getting Started: `ctx start`" - that's all.

## To Implement

Parse state.md/history.md/todos, integrate with locate, show confidence.
