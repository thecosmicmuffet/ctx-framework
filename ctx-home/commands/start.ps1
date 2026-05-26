#!/usr/bin/env pwsh
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'config.ps1')

$contextPath = Get-CtxContextPath
$config = Get-CtxConfig
$project = $config.current_project

if (-not $Quiet) {
    Write-Host "START: $project" -ForegroundColor Cyan
    Write-Host ''
}

& (Join-Path $PSScriptRoot 'chart.ps1') $project
Write-Host ''

$stateFile = Join-Path $contextPath 'state.dat'
if (Test-Path $stateFile) {
    try {
        $state = Get-Content $stateFile -Raw | ConvertFrom-Json
        Write-Host 'STATE' -ForegroundColor Yellow
        Write-Host "  phase: $($state.phase)"
        $active = @($state.work_items | Where-Object { $_.status -in @('active', 'next', 'blocked') } | Select-Object -First 5)
        foreach ($item in $active) {
            Write-Host "  [$($item.status)] $($item.id) $($item.title)" -ForegroundColor Gray
        }
        Write-Host ''
    } catch {}
}

$todosFile = Join-Path $contextPath 'todos.json'
if (Test-Path $todosFile) {
    try {
        $todos = Get-Content $todosFile -Raw | ConvertFrom-Json
        $open = @($todos.todos | Where-Object { $_.status -ne 'complete' })
        Write-Host 'TODOS' -ForegroundColor Yellow
        foreach ($todo in ($open | Select-Object -First 5)) {
            Write-Host "  [$($todo.id)] $($todo.title)" -ForegroundColor Gray
        }
        Write-Host ''
    } catch {}
}

Write-Host 'Ready.' -ForegroundColor Green
Write-Host 'Use: ctx state | ctx todos | ctx search <term> | ctx dock' -ForegroundColor DarkGray
