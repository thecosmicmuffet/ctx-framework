#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0)][string]$File,
    [switch]$Label,
    [switch]$Detail,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')

if ($Help) {
    Write-Host 'ctx trust - report freshness and confidence of context files'
    Write-Host ''
    Write-Host '  ctx trust'
    Write-Host '  ctx trust chart'
    Write-Host '  ctx trust --label'
    exit 0
}

$resolved = Resolve-CtxProject
if (-not $resolved.ProjectId) { Write-Host "No project context found. Run 'ctx register' first." -ForegroundColor Yellow; exit 1 }
$contextDir = $resolved.ContextDir
if (-not (Test-Path $contextDir)) { Write-Host "Context directory does not exist: $contextDir" -ForegroundColor Yellow; exit 1 }

function Get-TrustLevel([int]$AgeDays) {
    if ($AgeDays -le 7) { return 'FRESH' }
    if ($AgeDays -le 30) { return 'AGING' }
    return 'STALE'
}

function Get-Scope([string]$Path) {
    $norm = $Path.Replace('\\', '/')
    if ($norm -match '@ctx') { return 'Mind' }
    if ($norm -match 'https?://|^//') { return 'External' }
    return 'Body'
}

$targets = @()
if ($File) {
    $candidate = Join-Path $contextDir $File
    if (Test-Path $candidate) { $targets = @(Get-Item $candidate) }
    elseif (Test-Path $File) { $targets = @(Get-Item $File) }
    else { throw "File not found: $File" }
} else {
    $targets = @(Get-ChildItem $contextDir -File | Where-Object { $_.Extension -in @('.md', '.json', '') -or $_.Name -eq 'chart' })
}

$fresh = @(); $aging = @(); $stale = @(); $labels = @(); $now = Get-Date
foreach ($f in $targets) {
    $age = [int](($now - $f.LastWriteTime).TotalDays)
    $trust = Get-TrustLevel $age
    $entry = [PSCustomObject]@{ Name = $f.Name; AgeDays = $age; Trust = $trust; Scope = Get-Scope $f.FullName; Path = $f.FullName }
    switch ($trust) {
        'FRESH' { $fresh += $entry }
        'AGING' { $aging += $entry }
        'STALE' { $stale += $entry }
    }
    if ($Label) {
        $labels += [ordered]@{
            path = $f.Name
            project = $resolved.ProjectId
            trust = $trust
            age_days = $age
            scope = $entry.Scope
            timestamp = (Get-Date -Format 'o')
        }
    }
}

Write-Host "TRUST REPORT: $contextDir" -ForegroundColor Cyan
Write-Host ''
foreach ($group in @(@('FRESH', $fresh, 'Green'), @('AGING', $aging, 'Yellow'), @('STALE', $stale, 'Red'))) {
    if ($group[1].Count -gt 0) {
        Write-Host $group[0] -ForegroundColor $group[2]
        foreach ($item in $group[1] | Sort-Object AgeDays) {
            Write-Host "  $($item.Name.PadRight(28)) $($item.AgeDays) day(s) old" -ForegroundColor $group[2]
        }
        Write-Host ''
    }
}

if ($Detail) {
    $scopes = $targets | Group-Object { Get-Scope $_.FullName }
    Write-Host 'SCOPES' -ForegroundColor Yellow
    foreach ($scope in $scopes) {
        Write-Host "  $($scope.Name): $($scope.Count)" -ForegroundColor Gray
    }
}

if ($Label -and $labels.Count -gt 0) {
    $trainingDir = Join-Path (Find-AtCtxDir) 'training'
    if (-not (Test-Path $trainingDir)) { New-Item -ItemType Directory -Path $trainingDir -Force | Out-Null }
    $labelFile = Join-Path $trainingDir 'labels.jsonl'
    foreach ($label in $labels) { Add-Content $labelFile (($label | ConvertTo-Json -Compress)) }
    Write-Host ''
    Write-Host "Wrote $($labels.Count) label(s) to $labelFile" -ForegroundColor Gray
}
