#!/usr/bin/env pwsh
param(
    [string]$Name,
    [string]$Id,
    [switch]$Concept,
    [string]$Description,
    [string[]]$Keywords,
    [string[]]$Related,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')

if ($Help) {
    Write-Host 'ctx register - register a project or concept in @ctx'
    Write-Host ''
    Write-Host '  ctx register'
    Write-Host '  ctx register --name "My Project"'
    Write-Host '  ctx register --concept --name "Writing Retreat" --id writing-retreat'
    exit 0
}

if ($Keywords) { $Keywords = $Keywords | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
if ($Related)  { $Related  = $Related  | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ } }

$atCtxDir = Find-AtCtxDir
$projectsDir = Join-Path $atCtxDir 'projects'
$registryFile = Join-Path $atCtxDir 'registry.json'
if (-not (Test-Path $projectsDir)) { New-Item -ItemType Directory -Path $projectsDir -Force | Out-Null }
if (Test-Path $registryFile) { $registry = Get-Content $registryFile -Raw | ConvertFrom-Json } else { $registry = [PSCustomObject]@{ version = '1.0.0'; projects = [PSCustomObject]@{} } }

function Initialize-ProjectContext([string]$ProjectId) {
    $projCtxDir = Join-Path $projectsDir $ProjectId
    if (-not (Test-Path $projCtxDir)) { New-Item -ItemType Directory -Path $projCtxDir -Force | Out-Null }
    if (-not (Test-Path (Join-Path $projCtxDir 'chart'))) {
        Set-Content (Join-Path $projCtxDir 'chart') @('CTX 1.0', "@ $ProjectId (0f 0d)", '> ?', ': orienting', '; run ctx todos', '? none', '+ none yet', '~ steady')
    }
    if (-not (Test-Path (Join-Path $projCtxDir 'history.md'))) { Set-Content (Join-Path $projCtxDir 'history.md') '# History' }
    if (-not (Test-Path (Join-Path $projCtxDir 'state.dat'))) { @{ version='1.0'; phase='initial'; updated=(Get-Date -Format 'yyyy-MM-dd'); work_items=@(); confidence=@{ high=@(); medium=@(); low=@() } } | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $projCtxDir 'state.dat') }
    if (-not (Test-Path (Join-Path $projCtxDir 'state.json'))) { Set-Content (Join-Path $projCtxDir 'state.json') "// managed by ctx state" }
    if (-not (Test-Path (Join-Path $projCtxDir 'todos.json'))) { @{ version='1.0'; next_id=1; todos=@() } | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $projCtxDir 'todos.json') }
    if (-not (Test-Path (Join-Path $projCtxDir 'decisions.json'))) { @{ version='1.0'; decisions=@() } | ConvertTo-Json -Depth 10 | Set-Content (Join-Path $projCtxDir 'decisions.json') }
}

if ($Concept) {
    if (-not $Name -and -not $Id) { throw 'Concept registration requires --name or --id.' }
    $projectId = if ($Id) { $Id } else { ($Name -replace '[^a-zA-Z0-9-]', '-').ToLower().Trim('-') }
    $entry = [PSCustomObject]@{
        name = if ($Name) { $Name } else { $projectId }
        type = 'concept'
        description = $Description
        remotes = @()
        paths = @()
        worktree_roots = @()
        keywords = if ($Keywords) { @($Keywords) } else { @() }
        related = if ($Related) { @($Related) } else { @() }
    }
    if ($registry.projects.PSObject.Properties.Name -notcontains $projectId) {
        $registry.projects | Add-Member -NotePropertyName $projectId -NotePropertyValue $entry
    }
    $registry | ConvertTo-Json -Depth 10 | Set-Content $registryFile -Encoding UTF8
    Initialize-ProjectContext $projectId
    Write-Host "Registered concept: $projectId" -ForegroundColor Green
    exit 0
}

$cwd = (Get-Location).Path
$gitRemote = $null
$gitRoot = $null
try {
    $remoteOutput = git remote -v 2>$null
    if ($LASTEXITCODE -eq 0 -and $remoteOutput) {
        $fetchLine = $remoteOutput | Where-Object { $_ -match '\(fetch\)' } | Select-Object -First 1
        if ($fetchLine -match '^\S+\s+(\S+)\s+\(fetch\)') { $gitRemote = $matches[1] }
    }
    $gitRoot = (git rev-parse --show-toplevel 2>$null)
    if ($gitRoot) { $gitRoot = $gitRoot.Replace('/', '\\') }
} catch {}

$projectId = if ($Id) { $Id } elseif ($Name) { ($Name -replace '[^a-zA-Z0-9-]', '-').ToLower().Trim('-') } elseif ($gitRoot) { Split-Path $gitRoot -Leaf } else { Split-Path $cwd -Leaf }
$displayName = if ($Name) { $Name } else { $projectId }
$canonical = if ($gitRoot) { $gitRoot } else { $cwd }
$existing = if ($registry.projects.PSObject.Properties.Name -contains $projectId) { $registry.projects.$projectId } else { $null }
if (-not $existing) {
    $existing = [PSCustomObject]@{ name = $displayName; type='project'; remotes=@(); paths=@(); worktree_roots=@(); keywords=if($Keywords){@($Keywords)}else{@()}; related=if($Related){@($Related)}else{@()} }
    $registry.projects | Add-Member -NotePropertyName $projectId -NotePropertyValue $existing
}
if ($canonical -and $canonical -notin @($existing.paths)) { $existing.paths = @($existing.paths) + @($canonical) }
if ($gitRemote -and $gitRemote -notin @($existing.remotes)) { $existing.remotes = @($existing.remotes) + @($gitRemote) }
if ($Keywords) { foreach ($k in $Keywords) { if ($k -notin @($existing.keywords)) { $existing.keywords = @($existing.keywords) + @($k) } } }
if ($Related) { foreach ($r in $Related) { if ($r -notin @($existing.related)) { $existing.related = @($existing.related) + @($r) } } }
$existing.name = $displayName
$registry | ConvertTo-Json -Depth 10 | Set-Content $registryFile -Encoding UTF8
Initialize-ProjectContext $projectId
Write-Host "Registered project: $projectId" -ForegroundColor Green
Write-Host "  Path: $canonical" -ForegroundColor Gray
if ($gitRemote) { Write-Host "  Remote: $gitRemote" -ForegroundColor Gray }
