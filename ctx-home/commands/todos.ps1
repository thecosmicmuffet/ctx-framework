#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0)][string]$Action = 'show',
    [Parameter(Position = 1)][string]$Arg1,
    [Parameter(Position = 2)][string]$Arg2,
    [int]$Depth = 1,
    [string]$Title,
    [string]$Details,
    [string]$Description,
    [string]$Priority,
    [string]$Zone,
    [string[]]$Tag,
    [switch]$All,
    [switch]$Remove,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
if ($Description -and -not $Details) { $Details = $Description }
. (Join-Path $PSScriptRoot '..' 'lib' 'config.ps1')

$contextPath = Get-CtxContextPath
$config = Get-CtxConfig
$project = $config.current_project
$todosJson = Join-Path $contextPath 'todos.json'
$todosMd = Join-Path $contextPath 'TODOS.md'
$historyMd = Join-Path $contextPath 'history.md'

function Initialize-Todos {
    if (-not (Test-Path $todosJson)) {
        @{ version = '1.0'; next_id = 1; todos = @() } | ConvertTo-Json -Depth 10 | Set-Content $todosJson -Encoding UTF8
    }
}
function Get-TodosData { Initialize-Todos; return (Get-Content $todosJson -Raw | ConvertFrom-Json) }
function Save-TodosData($Data) {
    $Data | ConvertTo-Json -Depth 10 | Set-Content $todosJson -Encoding UTF8
    $incomplete = @($Data.todos | Where-Object { $_.status -ne 'complete' })
    $complete = @($Data.todos | Where-Object { $_.status -eq 'complete' })
    $lines = @('# TODO', '', "**Project:** $project", '')
    foreach ($group in @('near', 'medium', 'long')) {
        $items = @($incomplete | Where-Object { ($_.zone ?? 'medium') -eq $group })
        if ($items.Count -gt 0) {
            $lines += "## $($group.ToUpper())"
            $lines += ''
            foreach ($item in $items) {
                $lines += "- [ ] [$($item.id)] $($item.title)"
                if ($item.details) { $lines += "  - $($item.details)" }
            }
            $lines += ''
        }
    }
    if ($complete.Count -gt 0) {
        $lines += '## COMPLETED'
        $lines += ''
        foreach ($item in $complete) { $lines += "- [x] [$($item.id)] $($item.title)" }
        $lines += ''
    }
    Set-Content $todosMd $lines -Encoding UTF8
}
function Resolve-Id([string]$Raw) { $n = 0; if ([int]::TryParse($Raw, [ref]$n)) { return $n }; return $Raw }
function Find-Todo($Data, $Id) { return ($Data.todos | Where-Object { "$($_.id)" -eq "$Id" } | Select-Object -First 1) }

function Show-Todos {
    $data = Get-TodosData
    $items = @($data.todos)
    if (-not $All) { $items = @($items | Where-Object { $_.status -ne 'complete' }) }
    if ($Tag) { $items = @($items | Where-Object { $_.tags -and (@($Tag | Where-Object { $_ -in $_.tags }).Count -gt 0) }) }
    $done = @($data.todos | Where-Object { $_.status -eq 'complete' }).Count
    Write-Host 'TODO STATUS' -ForegroundColor Cyan
    Write-Host "  $done / $($data.todos.Count) completed" -ForegroundColor Gray
    Write-Host ''
    foreach ($group in @('near', 'medium', 'long')) {
        $groupItems = @($items | Where-Object { ($_.zone ?? 'medium') -eq $group } | Select-Object -First $Depth)
        if ($groupItems.Count -gt 0) {
            Write-Host ($group.ToUpper()) -ForegroundColor Yellow
            foreach ($item in $groupItems) {
                $tags = if ($item.tags) { ' [' + ($item.tags -join ',') + ']' } else { '' }
                Write-Host "  [$($item.id)] $($item.title)$tags" -ForegroundColor White
                if ($item.details) { Write-Host "      $($item.details)" -ForegroundColor DarkGray }
                if ($item.blocked_by -and $item.blocked_by.Count -gt 0) { Write-Host "      blocked by: $($item.blocked_by -join ', ')" -ForegroundColor Red }
            }
            Write-Host ''
        }
    }
}

function Add-Todo([string]$Text) {
    if (-not $Text) { throw 'Usage: ctx todos add <title>' }
    $data = Get-TodosData
    $todo = [ordered]@{
        id = $data.next_id
        title = $Text
        details = $Details
        status = 'next'
        priority = if ($Priority) { $Priority } else { 'medium' }
        zone = if ($Zone) { $Zone } else { 'near' }
        tags = if ($Tag) { @($Tag) } else { @() }
        blocked_by = @()
        created = (Get-Date -Format 'o')
    }
    $data.next_id += 1
    $data.todos += $todo
    Save-TodosData $data
    Write-Host "Added [$($todo.id)] $($todo.title)" -ForegroundColor Green
}

function Complete-Todo([string]$Id) {
    $data = Get-TodosData
    $todo = Find-Todo $data (Resolve-Id $Id)
    if (-not $todo) { throw "Todo not found: $Id" }
    $todo.status = 'complete'
    $todo.completed = (Get-Date -Format 'o')
    Save-TodosData $data
    Add-Content $historyMd ("- $(Get-Date -Format 'yyyy-MM-dd HH:mm') :: completed todo [$($todo.id)] $($todo.title)")
    Write-Host "Completed [$($todo.id)] $($todo.title)" -ForegroundColor Green
}

function Update-Todo([string]$Id) {
    $data = Get-TodosData
    $todo = Find-Todo $data (Resolve-Id $Id)
    if (-not $todo) { throw "Todo not found: $Id" }
    if ($Title) { $todo.title = $Title }
    if ($Details) { $todo.details = $Details }
    if ($Zone) { $todo.zone = $Zone }
    if ($Priority) { $todo.priority = $Priority }
    if ($Tag) {
        if ($Remove) { $todo.tags = @($todo.tags | Where-Object { $_ -notin $Tag }) }
        else { foreach ($t in $Tag) { if ($t -notin $todo.tags) { $todo.tags += $t } } }
    }
    Save-TodosData $data
    Write-Host "Updated [$($todo.id)]" -ForegroundColor Green
}

function Remove-Todo([string]$Id) {
    $data = Get-TodosData
    $before = $data.todos.Count
    $data.todos = @($data.todos | Where-Object { "$($_.id)" -ne "$Id" })
    if ($data.todos.Count -eq $before) { throw "Todo not found: $Id" }
    Save-TodosData $data
    Write-Host "Removed [$Id]" -ForegroundColor Yellow
}

function Block-Todo([string]$Id, [string]$Blocker) {
    $data = Get-TodosData
    $todo = Find-Todo $data (Resolve-Id $Id)
    if (-not $todo) { throw "Todo not found: $Id" }
    if (-not $todo.blocked_by) { $todo | Add-Member -NotePropertyName blocked_by -NotePropertyValue @() -Force }
    if ($Blocker -and $Blocker -notin $todo.blocked_by) { $todo.blocked_by += $Blocker }
    Save-TodosData $data
    Write-Host "Blocked [$($todo.id)] by $Blocker" -ForegroundColor Yellow
}

function Show-HelpText {
    Write-Host 'ctx todos - home todo management'
    Write-Host ''
    Write-Host '  ctx todos'
    Write-Host '  ctx todos add <title> [--details <text>] [--tag <tag>] [--zone near|medium|long]'
    Write-Host '  ctx todos complete <id>'
    Write-Host '  ctx todos update <id> [--title <text>] [--details <text>] [--tag <tag>]'
    Write-Host '  ctx todos cut <id>'
    Write-Host '  ctx todos block <id> <blocker-id>'
}

switch ($Action.ToLower()) {
    'show' { Show-Todos }
    'add' { Add-Todo $Arg1 }
    'complete' { Complete-Todo $Arg1 }
    'update' { Update-Todo $Arg1 }
    'cut' { Remove-Todo $Arg1 }
    'remove' { Remove-Todo $Arg1 }
    'block' { Block-Todo $Arg1 $Arg2 }
    'help' { Show-HelpText }
    default { Show-Todos }
}
