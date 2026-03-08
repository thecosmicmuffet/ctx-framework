#!/usr/bin/env pwsh
# ctx todos - Structured TODO management
# 
# Priority is ORDER, not tags:
#   high   = next incomplete todo (position 1)
#   medium = within next 3 incomplete (positions 2-3)
#   low    = push to end of incomplete
#
# Blocking moves todo after blocker automatically.
# Delegate marks independent todos for parallel agent work.

param(
    [Parameter(Position=0)]
    [string]$Action = "show",
    
    [Parameter(Position=1)]
    [string]$Arg1,
    
    [Parameter(Position=2)]
    [string]$Arg2,
    
    [int]$Depth = 1,
    [string]$Title,
    [string]$Details,
    [string]$Description,  # Alias for Details
    [int]$After = -1,
    [int]$Before = -1,
    [string]$Note,
    [string]$Priority,
    [int]$BlockedBy = -1,
    [string[]]$Tag,        # Filter by tag(s) or add tags
    [string[]]$Tags,       # Alias for Tag
    [int]$AdoId,           # Link to ADO work item
    [switch]$Delegate,
    [switch]$Unblock,
    [switch]$Remove,
    [switch]$Quiet,
    [switch]$All           # Show all todos including complete
)

$ErrorActionPreference = "Stop"

# Resolve aliases - normalize parameter names
if ($Description -and -not $Details) { $Details = $Description }
if ($Tags -and -not $Tag) { $Tag = $Tags }

# Action aliases - map common patterns to canonical actions
$ActionAliases = @{
    "done" = "complete"
    "finish" = "complete"
    "new" = "add"
    "create" = "add"
    "rm" = "cut"
    "remove" = "cut"
    "delete" = "cut"
    "edit" = "update"
    "modify" = "update"
    "info" = "details"
    "view" = "details"
    "list" = "show"
    "ls" = "show"
    "next" = "show"  # ctx todos next = show next
    "tag" = "tags"   # ctx todos tag <id> <tag> = add tag
}
if ($ActionAliases.ContainsKey($Action.ToLower())) {
    $Action = $ActionAliases[$Action.ToLower()]
}

# Load shared config library
. (Join-Path $PSScriptRoot ".." "lib" "config.ps1")

# Get context path using shared function
$contextPath = Get-CtxContextPath
$config = Get-CtxConfig
$gitRoot = $config.projects.($config.current_project).git_root

# Augmented header
if (-not $Quiet) {
    $relativeCtx = $contextPath -replace [regex]::Escape($gitRoot), "[git]"
    Write-Host "[git:$gitRoot ctx:$relativeCtx cmd:todos:exists]" -ForegroundColor DarkGray
    Write-Host ""
}

# File paths
$todosJson = Join-Path $contextPath "todos.json"
$todosMd = Join-Path $contextPath "TODOS.md"
$historyMd = Join-Path $contextPath "history.md"

# Initialize todos.json if it doesn't exist
function Initialize-Todos {
    if (-not (Test-Path $todosJson)) {
        $initial = @{
            version = "1.0"
            next_id = 1
            todos = @()
        }
        $initial | ConvertTo-Json -Depth 10 | Set-Content $todosJson
    }
}

# Load todos
function Get-TodosData {
    Initialize-Todos
    return Get-Content $todosJson -Raw | ConvertFrom-Json
}

# Save todos
function Save-TodosData {
    param($Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content $todosJson
    Generate-TodosMd $Data
}

# Generate TODOS.md from JSON
function Generate-TodosMd {
    param($Data)
    
    $content = @"
# TODO - StartMenu → Start Migration

**Progress:** $($Data.todos | Where-Object {$_.status -eq "complete" -or $_.completed} | Measure-Object | Select-Object -ExpandProperty Count)/$($Data.todos.Count) completed

---

"@
    
    foreach ($todo in $Data.todos) {
        $isComplete = ($todo.status -eq "complete") -or $todo.completed
        $checkbox = if ($isComplete) { "[x]" } else { "[ ]" }
        $content += "## $checkbox [$($todo.id)] $($todo.title)`n`n"
        
        if ($todo.details -or $todo.description) {
            $content += "$($todo.details ?? $todo.description)`n`n"
        }
        
        if ($isComplete -and $todo.completed_date) {
            $content += "_Completed: $($todo.completed_date)_`n`n"
        }
        
        $content += "---`n`n"
    }
    
    $content | Set-Content $todosMd
}

# Show progress and upcoming todos
function Show-Todos {
    param(
        [int]$Depth,
        [string[]]$FilterTags,
        [switch]$ShowAll
    )
    
    $data = Get-TodosData
    # Support both 'completed' (boolean) and 'status' (string) schemas
    $completed = ($data.todos | Where-Object {$_.completed -eq $true -or $_.status -eq "complete"}).Count
    $total = $data.todos.Count
    $remaining = $total - $completed
    
    Write-Host "=== TODO STATUS ===" -ForegroundColor Cyan
    Write-Host "Progress: $completed/$total completed ($remaining remaining)" -ForegroundColor White
    
    # Show active filter if any
    if ($FilterTags -and $FilterTags.Count -gt 0) {
        Write-Host "Filter: tags contain [$($FilterTags -join ', ')]" -ForegroundColor DarkGray
    }
    Write-Host ""
    
    $allTodos = $data.todos
    
    # Apply tag filter if specified
    if ($FilterTags -and $FilterTags.Count -gt 0) {
        $allTodos = @($allTodos | Where-Object {
            $todoTags = $_.tags
            if (-not $todoTags) { return $false }
            foreach ($ft in $FilterTags) {
                if ($todoTags -contains $ft) { return $true }
            }
            return $false
        })
        if ($allTodos.Count -eq 0) {
            Write-Host "No todos matching tags: $($FilterTags -join ', ')" -ForegroundColor Yellow
            return
        }
    }
    
    $incomplete = @($allTodos | Where-Object {-not $_.completed -and $_.status -ne "complete" -and $_.status -ne "resolved"})
    $completedTodos = @($allTodos | Where-Object {$_.completed -eq $true -or $_.status -eq "complete" -or $_.status -eq "resolved"})
    
    # Get completed IDs to check blockers
    $completedIds = @($data.todos | Where-Object {$_.completed -or $_.status -eq "complete"} | ForEach-Object {$_.id})
    
    # Check if a todo is blocked (has uncompleted blockers)
    function Test-Blocked {
        param($Todo)
        if ($null -eq $Todo.blocked_by -or $Todo.blocked_by.Count -eq 0) { return $false }
        foreach ($blockerId in $Todo.blocked_by) {
            if ($blockerId -notin $completedIds) { return $true }
        }
        return $false
    }
    
    # Separate: blocked, delegatable (parallel-safe), sequential (critical path)
    $blocked = @($incomplete | Where-Object { Test-Blocked $_ })
    $unblocked = @($incomplete | Where-Object { -not (Test-Blocked $_) })
    $delegatable = @($unblocked | Where-Object {$_.delegatable -eq $true})
    $sequential = @($unblocked | Where-Object {$_.delegatable -ne $true})
    
    # Show next sequential todo (the critical path)
    if ($sequential.Count -gt 0) {
        Write-Host "--- NEXT ---" -ForegroundColor Yellow
        $next = $sequential[0]
        Write-Host "[$($next.id)] $($next.title)" -ForegroundColor Green
        if ($next.details) {
            Write-Host "  $($next.details)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    # Show delegatable todos (can be done in parallel by agents)
    if ($delegatable.Count -gt 0) {
        Write-Host "--- DELEGATABLE ($($delegatable.Count)) ---" -ForegroundColor Magenta
        Write-Host "(Independent tasks - can run in parallel)" -ForegroundColor DarkGray
        foreach ($todo in $delegatable) {
            Write-Host "[$($todo.id)] $($todo.title)" -ForegroundColor Magenta
        }
        Write-Host ""
    }
    
    # Show upcoming sequential if depth > 1
    if ($Depth -gt 1 -and $sequential.Count -gt 1) {
        $upcoming = $sequential | Select-Object -Skip 1 -First ($Depth - 1)
        if ($upcoming) {
            Write-Host "--- UPCOMING ($($Depth - 1) more) ---" -ForegroundColor Yellow
            foreach ($todo in $upcoming) {
                Write-Host "[$($todo.id)] $($todo.title)" -ForegroundColor White
            }
            Write-Host ""
        }
    }
    
    # Show blocked todos count
    if ($blocked.Count -gt 0) {
        Write-Host "--- BLOCKED ($($blocked.Count)) ---" -ForegroundColor DarkYellow
        foreach ($todo in $blocked) {
            $blockerIds = ($todo.blocked_by | Where-Object { $_ -notin $completedIds }) -join ", "
            Write-Host "[$($todo.id)] $($todo.title) (by: $blockerIds)" -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
    
    if ($incomplete.Count -eq 0) {
        Write-Host "No pending todos! 🎉" -ForegroundColor Green
        Write-Host ""
    }
    
    # Show completed if --all flag
    if ($ShowAll -and $completedTodos.Count -gt 0) {
        Write-Host "--- COMPLETED ($($completedTodos.Count)) ---" -ForegroundColor DarkGreen
        foreach ($todo in $completedTodos) {
            $date = if ($todo.completed_date) { " ($($todo.completed_date))" } else { "" }
            Write-Host "[$($todo.id)] $($todo.title)$date" -ForegroundColor DarkGreen
        }
        Write-Host ""
    }
}

# Add a new todo
function Add-Todo {
    param(
        [string]$Title,
        [string]$Details,
        [int]$After,
        [int]$Before,
        [string[]]$TodoTags,
        [int]$TodoAdoId
    )
    
    $data = Get-TodosData
    
    $newTodo = @{
        id = $data.next_id
        title = $Title
        status = "not-started"
        completed = $false
        completed_date = $null
        completed_note = $null
        created_date = (Get-Date -Format "yyyy-MM-dd HH:mm")
    }
    
    # Add optional fields
    if ($Details) { $newTodo.description = $Details }
    if ($TodoTags -and $TodoTags.Count -gt 0) { $newTodo.tags = $TodoTags }
    if ($TodoAdoId -gt 0) { $newTodo.ado_id = $TodoAdoId }
    
    $data.next_id++
    
    # Determine insertion position
    if ($After -ge 0) {
        $index = [array]::FindIndex($data.todos, [Predicate[object]]{param($t) $t.id -eq $After})
        if ($index -ge 0) {
            $data.todos = @($data.todos[0..$index]) + $newTodo + @($data.todos[($index+1)..($data.todos.Count-1)])
        } else {
            Write-Error "Todo ID $After not found"
            return
        }
    } elseif ($Before -ge 0) {
        $index = [array]::FindIndex($data.todos, [Predicate[object]]{param($t) $t.id -eq $Before})
        if ($index -ge 0) {
            if ($index -eq 0) {
                $data.todos = @($newTodo) + $data.todos
            } else {
                $data.todos = @($data.todos[0..($index-1)]) + $newTodo + @($data.todos[$index..($data.todos.Count-1)])
            }
        } else {
            Write-Error "Todo ID $Before not found"
            return
        }
    } else {
        $data.todos += $newTodo
    }
    
    Save-TodosData $data
    Write-Host "✓ Added todo [$($newTodo.id)]: $Title" -ForegroundColor Green
}

# Complete a todo
function Complete-Todo {
    param(
        [int]$Id,
        [string]$Note
    )
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    if ($todo.completed) {
        Write-Warning "Todo [$Id] already completed"
        return
    }
    
    $todo.completed = $true
    $todo.completed_date = Get-Date -Format "yyyy-MM-dd HH:mm"
    $todo.completed_note = $Note
    
    Save-TodosData $data
    
    # Update history.md
    Update-History $todo $Note
    
    Write-Host "✓ Completed todo [$Id]: $($todo.title)" -ForegroundColor Green
}

# Update history.md with completed todo
function Update-History {
    param($Todo, $Note)
    
    if (-not (Test-Path $historyMd)) {
        return
    }
    
    $history = Get-Content $historyMd -Raw
    $date = Get-Date -Format "yyyy-MM-dd"
    $time = Get-Date -Format "HH:mm"
    
    # Find today's entry or create new
    $todayPattern = "### $date"
    
    $entry = "- [$time] ✓ $($Todo.title)"
    if ($Note) {
        $entry += " - $Note"
    }
    
    if ($history -match [regex]::Escape($todayPattern)) {
        # Add to today's entry (after the header line)
        $history = $history -replace "($todayPattern.*?\n)", "`$1$entry`n"
    } else {
        # Create new entry at the top of timeline
        $timelinePattern = "## Timeline \(Reverse Chronological\)"
        $newEntry = @"
### $date
$entry

"@
        $history = $history -replace "($timelinePattern\s*\n)", "`$1`n$newEntry"
    }
    
    $history | Set-Content $historyMd
}

# Cut (remove) a todo
function Cut-Todo {
    param([int]$Id)
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    $data.todos = @($data.todos | Where-Object {$_.id -ne $Id})
    Save-TodosData $data
    
    Write-Host "✓ Removed todo [$Id]: $($todo.title)" -ForegroundColor Yellow
}

# Show todo details
function Show-TodoDetails {
    param([int]$Id)
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    Write-Host "=== TODO [$($todo.id)] ===" -ForegroundColor Cyan
    Write-Host "Title: $($todo.title)" -ForegroundColor White
    Write-Host "Status: $(if ($todo.completed) {'✓ Completed'} else {'○ Pending'})" -ForegroundColor $(if ($todo.completed) {'Green'} else {'Yellow'})
    Write-Host "Created: $($todo.created_date)" -ForegroundColor Gray
    
    if ($todo.completed) {
        Write-Host "Completed: $($todo.completed_date)" -ForegroundColor Gray
        if ($todo.completed_note) {
            Write-Host "Note: $($todo.completed_note)" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    if ($todo.details) {
        Write-Host "Details:" -ForegroundColor Yellow
        Write-Host $todo.details
    } else {
        Write-Host "(No details)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

# Update todo details
function Update-TodoDetails {
    param(
        [int]$Id,
        [string]$NewDetails,
        [switch]$Remove
    )
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    if ($Remove) {
        $todo.details = $null
        Write-Host "✓ Removed details from todo [$Id]" -ForegroundColor Yellow
    } else {
        $todo.details = $NewDetails
        Write-Host "✓ Updated details for todo [$Id]" -ForegroundColor Green
    }
    
    Save-TodosData $data
}

# Set priority by reordering (priority IS position)
# high = move to first incomplete position
# medium = move to position 2-3 among incomplete
# low = move to end of incomplete
function Set-Priority {
    param(
        [int]$Id,
        [string]$Level
    )
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    if ($todo.completed) {
        Write-Warning "Cannot prioritize completed todo [$Id]"
        return
    }
    
    # Remove from current position
    $otherTodos = @($data.todos | Where-Object {$_.id -ne $Id})
    $completedTodos = @($otherTodos | Where-Object {$_.completed})
    $incompleteTodos = @($otherTodos | Where-Object {-not $_.completed})
    
    # Determine target position among incomplete
    switch ($Level.ToLower()) {
        "high" {
            # Position 0 = next
            $targetPos = 0
            Write-Host "✓ [$Id] → HIGH priority (next)" -ForegroundColor Green
        }
        "medium" {
            # Position 1-2 (after next, within top 3)
            $targetPos = [Math]::Min(1, $incompleteTodos.Count)
            Write-Host "✓ [$Id] → MEDIUM priority (top 3)" -ForegroundColor Yellow
        }
        "low" {
            # End of incomplete
            $targetPos = $incompleteTodos.Count
            Write-Host "✓ [$Id] → LOW priority (end)" -ForegroundColor DarkGray
        }
        default {
            Write-Error "Unknown priority: $Level. Use: high, medium, low"
            return
        }
    }
    
    # Rebuild: completed + reordered incomplete
    if ($targetPos -eq 0) {
        $reordered = @($todo) + $incompleteTodos
    } elseif ($targetPos -ge $incompleteTodos.Count) {
        $reordered = $incompleteTodos + @($todo)
    } else {
        $reordered = @($incompleteTodos[0..($targetPos-1)]) + @($todo) + @($incompleteTodos[$targetPos..($incompleteTodos.Count-1)])
    }
    
    $data.todos = $completedTodos + $reordered
    Save-TodosData $data
}

# Block todo - moves it after the blocker
function Set-BlockedBy {
    param(
        [int]$Id,
        [int]$BlockerId
    )
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    $blocker = $data.todos | Where-Object {$_.id -eq $BlockerId}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    if (-not $blocker) {
        Write-Error "Blocker ID $BlockerId not found"
        return
    }
    
    if ($todo.completed) {
        Write-Warning "Cannot block completed todo [$Id]"
        return
    }
    
    # Remove todo from current position
    $otherTodos = @($data.todos | Where-Object {$_.id -ne $Id})
    
    # Find blocker's position and insert after it
    $blockerIndex = -1
    for ($i = 0; $i -lt $otherTodos.Count; $i++) {
        if ($otherTodos[$i].id -eq $BlockerId) {
            $blockerIndex = $i
            break
        }
    }
    
    if ($blockerIndex -eq $otherTodos.Count - 1) {
        $data.todos = $otherTodos + @($todo)
    } else {
        $data.todos = @($otherTodos[0..$blockerIndex]) + @($todo) + @($otherTodos[($blockerIndex+1)..($otherTodos.Count-1)])
    }
    
    Write-Host "✓ [$Id] blocked by [$BlockerId] - moved after it" -ForegroundColor Yellow
    Save-TodosData $data
}

# Toggle delegatable status (can be worked on independently/in parallel)
function Set-Delegatable {
    param(
        [int]$Id,
        [bool]$Value = $true
    )
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    # Add or update delegatable property
    if ($Value) {
        $todo | Add-Member -NotePropertyName "delegatable" -NotePropertyValue $true -Force
        Write-Host "✓ [$Id] marked as DELEGATABLE (can run in parallel)" -ForegroundColor Magenta
    } else {
        $todo | Add-Member -NotePropertyName "delegatable" -NotePropertyValue $false -Force
        Write-Host "✓ [$Id] marked as SEQUENTIAL (requires order)" -ForegroundColor White
    }
    
    Save-TodosData $data
}

# Update todo properties (title, details, blocked_by, tags)
function Update-Todo {
    param(
        [int]$Id,
        [string]$NewTitle,
        [string]$NewDetails,
        [switch]$ClearBlockers,
        [string[]]$AddTags
    )
    
    $data = Get-TodosData
    $todo = $data.todos | Where-Object {$_.id -eq $Id}
    
    if (-not $todo) {
        Write-Error "Todo ID $Id not found"
        return
    }
    
    $changes = @()
    
    if ($NewTitle) {
        $todo.title = $NewTitle
        $changes += "title"
    }
    
    if ($NewDetails) {
        # Support both 'details' and 'description' field names
        if ($todo.PSObject.Properties['description']) {
            $todo.description = $NewDetails
        } else {
            $todo | Add-Member -NotePropertyName "description" -NotePropertyValue $NewDetails -Force
        }
        $changes += "description"
    }
    
    if ($ClearBlockers) {
        $todo | Add-Member -NotePropertyName "blocked_by" -NotePropertyValue @() -Force
        $changes += "cleared blockers"
    }
    
    if ($AddTags -and $AddTags.Count -gt 0) {
        if (-not $todo.tags) {
            $todo | Add-Member -NotePropertyName "tags" -NotePropertyValue @() -Force
        }
        foreach ($t in $AddTags) {
            if ($t -notin $todo.tags) { $todo.tags += $t }
        }
        $changes += "tags"
    }
    
    if ($changes.Count -eq 0) {
        Write-Host "No changes specified. Use --title, --details, --tag, or --unblock" -ForegroundColor Yellow
        return
    }
    
    Save-TodosData $data
    Write-Host "✓ [$Id] updated: $($changes -join ', ')" -ForegroundColor Green
}

# Main command router
if ([string]::IsNullOrWhiteSpace($Action)) {
    $Action = "show"
}

switch ($Action.ToLower()) {
    "show" {
        Show-Todos -Depth $Depth -FilterTags $Tag -ShowAll:$All
    }
    "add" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos add <title> [--details <details>] [--tag <tag>] [--ado-id <id>] [--after <id>] [--before <id>] [--priority high|medium|low] [--delegate]"
            exit 1
        }
        Add-Todo -Title $Arg1 -Details $Details -After $After -Before $Before -TodoTags $Tag -TodoAdoId $AdoId
        
        # Apply priority if specified
        if ($Priority) {
            $data = Get-TodosData
            $newId = $data.next_id - 1
            Set-Priority -Id $newId -Level $Priority
        }
        
        # Mark as delegatable if specified
        if ($Delegate) {
            $data = Get-TodosData
            $newId = $data.next_id - 1
            Set-Delegatable -Id $newId -Value $true
        }
    }
    "complete" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos complete <id> [--note <note>]"
            exit 1
        }
        Complete-Todo -Id ([int]$Arg1) -Note $Note
    }
    "cut" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos cut <id>"
            exit 1
        }
        Cut-Todo -Id ([int]$Arg1)
    }
    "details" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos details <id> [new_details] [--remove]"
            exit 1
        }
        if ($Arg2 -or $Remove) {
            Update-TodoDetails -Id ([int]$Arg1) -NewDetails $Arg2 -Remove:$Remove
        } else {
            Show-TodoDetails -Id ([int]$Arg1)
        }
    }
    "priority" {
        if (-not $Arg1 -or -not $Arg2) {
            Write-Error "Usage: ctx todos priority <id> <high|medium|low>"
            exit 1
        }
        Set-Priority -Id ([int]$Arg1) -Level $Arg2
    }
    "block" {
        if (-not $Arg1 -or -not $Arg2) {
            Write-Error "Usage: ctx todos block <id> <blocker_id>"
            exit 1
        }
        Set-BlockedBy -Id ([int]$Arg1) -BlockerId ([int]$Arg2)
    }
    "delegate" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos delegate <id> [--remove]"
            exit 1
        }
        Set-Delegatable -Id ([int]$Arg1) -Value (-not $Remove)
    }
    "update" {
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos update <id> [--title <text>] [--details <text>] [--unblock] [--tag <tag>]"
            exit 1
        }
        Update-Todo -Id ([int]$Arg1) -NewTitle $Title -NewDetails $Details -ClearBlockers:$Unblock -AddTags $Tag
    }
    "tags" {
        # ctx todos tags <id> <tag1,tag2,...> [--remove]
        if (-not $Arg1) {
            Write-Error "Usage: ctx todos tags <id> [tag1,tag2,...] [--remove]"
            exit 1
        }
        $data = Get-TodosData
        $todo = $data.todos | Where-Object {$_.id -eq [int]$Arg1}
        if (-not $todo) {
            Write-Error "Todo ID $Arg1 not found"
            exit 1
        }
        
        # Ensure tags array exists
        if (-not $todo.tags) {
            $todo | Add-Member -NotePropertyName "tags" -NotePropertyValue @() -Force
        }
        
        if ($Arg2) {
            $newTags = $Arg2 -split ','
            if ($Remove) {
                $todo.tags = @($todo.tags | Where-Object { $_ -notin $newTags })
                Write-Host "✓ [$Arg1] removed tags: $($newTags -join ', ')" -ForegroundColor Yellow
            } else {
                foreach ($t in $newTags) {
                    if ($t -notin $todo.tags) { $todo.tags += $t }
                }
                Write-Host "✓ [$Arg1] added tags: $($newTags -join ', ')" -ForegroundColor Green
            }
            Save-TodosData $data
        } else {
            # Just show current tags
            $currentTags = if ($todo.tags -and $todo.tags.Count -gt 0) { $todo.tags -join ', ' } else { "(none)" }
            Write-Host "[$Arg1] tags: $currentTags" -ForegroundColor Cyan
        }
    }
    "help" {
        Write-Host "ctx todos - Structured TODO management" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Commands:" -ForegroundColor Yellow
        Write-Host "  show [-Depth n] [--tag X]    Show next todo + delegatable tasks"
        Write-Host "       --all                   Include completed todos"
        Write-Host "       --tag <tag>             Filter by tag(s)"
        Write-Host "  add <title> [options]        Add new todo"
        Write-Host "    --details <text>           Set details/description"
        Write-Host "    --tag <tag1,tag2>          Add tags (comma-separated)"
        Write-Host "    --ado-id <id>              Link to ADO work item"
        Write-Host "    --after <id>               Insert after todo"
        Write-Host "    --before <id>              Insert before todo"
        Write-Host "    --priority high|med|low    Set priority (reorders)"
        Write-Host "    --delegate                 Mark as delegatable"
        Write-Host "  complete <id> [--note]       Mark complete, update history"
        Write-Host "  cut <id>                     Remove todo (aliases: rm, delete)"
        Write-Host "  update <id> [options]        Update todo in place (alias: edit)"
        Write-Host "    --title <text>             Change title"
        Write-Host "    --details <text>           Change details/description"
        Write-Host "    --tag <tag>                Add tag(s)"
        Write-Host "    --unblock                  Clear blocked_by array"
        Write-Host "  tags <id> [tag1,tag2]        View/add/remove tags"
        Write-Host "    --remove                   Remove specified tags"
        Write-Host "  details <id> [text]          View or update details"
        Write-Host "  priority <id> <level>        Reorder by priority"
        Write-Host "  block <id> <blocker_id>      Move todo after blocker"
        Write-Host "  delegate <id> [--remove]     Mark as parallel-safe"
        Write-Host ""
        Write-Host "Aliases:" -ForegroundColor Yellow
        Write-Host "  done, finish = complete    new, create = add"
        Write-Host "  rm, delete   = cut         edit, modify = update"
        Write-Host "  list, ls     = show        info, view = details"
        Write-Host ""
        Write-Host "Priority = Order:" -ForegroundColor Yellow
        Write-Host "  high   = next incomplete (position 1)"
        Write-Host "  medium = within top 3 incomplete"
        Write-Host "  low    = end of incomplete list"
        Write-Host ""
    }
    default {
        Write-Error "Unknown action: $Action. Use 'ctx todos help' for usage."
        exit 1
    }
}
