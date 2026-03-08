# Kit: locate

## Purpose

**Identity resolution for multi-project context management.** Determines which project/process the current iteration is attending to, and provides stable location anchors that other scripts can query to avoid path fragmentation.

## Problem Statement

Without location resolution:
- Agents work in wrong repository clone (D:\oscl vs D:\oscl_2)
- Commands execute on wrong project context
- Multi-project work creates confusion about "which context?"
- Path logic gets duplicated across scripts (fragmentation)
- No single point of correction when paths change

## Core Principle

**Locate is about IDENTITY, not just paths.** It answers: "Which process is this iteration attending to?" using stable anchors (git root, solution files, language markers, framework evidence).

## Disambiguation

Three location-related commands:
- `ctx locate` - Determine **project identity** (which git repo, which clone) (this command)
- `ctx find Symbol` - Find files/symbols **in codebase**
- `ctx search term` - Search for text **in .ctx files**

Scope: **project identity** (git root, which repo clone), not file locations.

## Behavior Specification

```bash
./ctx locate [--show] [--set project-name] [--init] [--list]
```

### Show current location (default)
```bash
./ctx locate
```

**Output:**
```
LOCATION IDENTITY
=================
Project:    StartMenu
Git Root:   D:\oscl
Context:    [git]\Src\Components\StartMenu\.ctx
Solution:   [git]\Src\Components\StartMenu\StartMenu.sln
Framework:  ctx @ [git]\Src\Components\StartMenu\scripts\ctx

Anchors:
  ✓ .git found at D:\oscl
  ✓ .sln found at [project]
  ✓ .ctx found at [project]
  ✓ ctx found at [project]\scripts\ctx

Confidence: HIGH (all anchors present)
```

### Initialize location for new project
```bash
./ctx locate --init
```

Interactive: Detect git root, solution file, confirm context location, save to `.ctxconfig`.

### Switch between projects
```bash
./ctx locate --set StartMenu      # Switch to known project
```

### List known projects
```bash
./ctx locate --list
```

## Configuration Structure

Location: `[project-root]/.ctxconfig`

```json
{
  "version": "1.0",
  "current_project": "StartMenu",
  "projects": {
    "StartMenu": {
      "git_root": "D:\\oscl",
      "project_root": "[git]\\Src\\Components\\StartMenu",
      "context_dir": "[project]\\.ctx",
      "framework_dir": "[project]\\scripts\\ctx",
      "anchors": {
        "solution": "[project]\\StartMenu.sln",
        "language": "cpp",
        "frameworks": ["winrt", "xaml"]
      }
    }
  },
  "breadcrumbs": {
    "StartMenu": []
  }
}
```

### Path Variables

- `[git]` - Git repository root
- `[project]` - Project root
- `[context]` - Context directory
- `[framework]` - Framework location

## Router Integration

### Augmented Prompt Output

```bash
ctx search authentication
[git:D:\oscl ctx:[git]\...\StartMenu\.ctx cmd:search:exists]
────────────────────────────────────────────────────────
SEARCH: "authentication" in .ctx/
```

Toggleable with `--quiet` flag or config setting.

### Environment Variables

Commands receive:
- `CTX_GIT_ROOT`
- `CTX_PROJECT_ROOT`
- `CTX_CONTEXT_DIR`
- `CTX_PROJECT_NAME`
- `CTX_FRAMEWORK_DIR`

## Use Cases

### Call from script
```powershell
$projectRoot = & ctx locate --var project_root
cd $projectRoot
```

### Multi-project work
```bash
ctx locate --set StartMenu
ctx index
# ... work ...
ctx locate --set GameEngine
```

### Validation
Router validates git root matches config, warns on mismatch.

### Bootstrap integration
Bootstrap generates initial `.ctxconfig` automatically.

## Breadcrumb System

Projects can reference each other:

```json
"breadcrumbs": {
  "StartMenu": [
    {
      "project": "GameEngine",
      "note": "Shared UI patterns"
    }
  ]
}
```

## Confidence Levels

**HIGH**: All anchors present, git root matches  
**MEDIUM**: Some anchors missing  
**LOW**: Git root mismatch detected  

## To Implement

1. Create `ctx-commands/locate.ps1` and `locate.sh`
2. Update bootstrap to generate `.ctxconfig`
3. Router loads config, expands variables, shows header
4. Update existing commands to use resolved paths

## Philosophy

**Identity before geography.** Establish which process we're serving (project name, anchors, frameworks), then paths follow. Single source of truth in `.ctxconfig` prevents fragmentation.
