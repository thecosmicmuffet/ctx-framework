# Kit: find

## Purpose

**Find files/symbols in codebase without filesystem exploration.** Answers "where is X?" deterministically from codebase.md or indexed data.

## Disambiguation

Three location-related commands:
- `ctx find Symbol` - Find files/symbols **in codebase** (this command)
- `ctx locate` - Determine **project identity** (git root, which clone, switch projects)
- `ctx search term` - Search for text **in .ctx files**

Scope: **codebase** (source files), not context files.

## Problem

Agents do `Get-ChildItem -Recurse` or `grep -r` to find files, exploding context with filesystem noise. This violates wedge principle.

## Behavior

```bash
ctx where GroupManagementControl
```

**Output:**
```
LOCATION: GroupManagementControl

Files:
  lib/GroupManagementControl.xaml
  lib/GroupManagementControl.xaml.h
  lib/GroupManagementControl.xaml.cpp

Related:
  lib/UserCategoriesViewModel.h (references)
  
Last modified: 2025-12-08
```

## Design Principle

**Command over exploration.** Don't search filesystem. Parse codebase.md or maintain index. Answer instantly.

## Advanced

```bash
ctx where --symbol HandleDragDrop    # Find symbol definition
ctx where --type DependencyProperty  # Find all dependency properties
ctx where --pattern "Category*"      # Pattern matching
```

Could build index on first run, cache for speed.

## To Implement

1. Parse codebase.md for file references
2. Or: Build file index (cached)
3. Support symbol search via tags/ctags
4. Fast pattern matching
