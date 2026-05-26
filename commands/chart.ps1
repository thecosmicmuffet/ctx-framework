#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0)]
    [string]$ProjectOrScope,
    [switch]$Write,
    [switch]$Dock,
    [string]$Set,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')
$_extra = Join-Path $PSScriptRoot '..' 'lib' 'resolve-additions.ps1'
if (Test-Path $_extra) { . $_extra }

function Get-Stats([string]$Dir) {
    if (-not (Test-Path $Dir)) { return '0f 0d' }
    $files = @(Get-ChildItem $Dir -File -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) { return '0f 0d' }
    $days = ((Get-Date) - ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime).Days
    return "$($files.Count)f ${days}d"
}

function Get-DefaultChart([string]$ProjectId, [string]$ContextDir) {
    @(
        'CTX 1.0',
        "@ $ProjectId ($(Get-Stats $ContextDir))",
        '> focus the next meaningful step',
        ': orienting',
        '; run ctx todos',
        '? none',
        '+ none yet',
        '~ steady'
    )
}

function Load-ChartLines([string]$ContextDir, [string]$ProjectId) {
    $chartFile = Join-Path $ContextDir 'chart'
    if (Test-Path $chartFile) { return @(Get-Content $chartFile) }
    return (Get-DefaultChart -ProjectId $ProjectId -ContextDir $ContextDir)
}

function Save-ChartLines([string]$ContextDir, [string[]]$Lines) {
    if (-not (Test-Path $ContextDir)) { New-Item -ItemType Directory -Path $ContextDir -Force | Out-Null }
    Set-Content (Join-Path $ContextDir 'chart') $Lines -Encoding UTF8
}

function Set-ChartField([string[]]$Lines, [string]$FieldSpec, [string]$ProjectId, [string]$ContextDir) {
    if ($FieldSpec -notmatch '^([@>:;?+~!\.])\s*(.*)$') { throw "Use: ctx chart --set '> new goal'" }
    $token = $matches[1]
    $value = $matches[2]
    $updated = @()
    $found = $false
    foreach ($line in $Lines) {
        if ($line -match ('^' + [regex]::Escape($token) + '\s')) {
            $updated += "$token $value"
            $found = $true
        } else {
            $updated += $line
        }
    }
    if (-not $found) { $updated += "$token $value" }
    if ($token -ne '@') { $updated[1] = "@ $ProjectId ($(Get-Stats $ContextDir))" }
    return ,$updated
}

function Get-ScentHint([string]$ProjectId) {
    $scentFile = Join-Path (Find-AtCtxDir) 'scent.jsonl'
    if (-not (Test-Path $scentFile)) { return $null }
    $now = Get-Date
    $matches = @()
    Get-Content $scentFile -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $item = $_ | ConvertFrom-Json
            if ([datetime]$item.expires_at -gt $now -and ($item.project -eq $ProjectId -or $item.project -eq 'global')) {
                $matches += $item
            }
        } catch {}
    }
    if ($matches.Count -eq 0) { return $null }
    return ($matches | Sort-Object { -[double]$_.salience } | Select-Object -First 1)
}

if ($Help) {
    Write-Host 'ctx chart - compressed orientation for home use'
    Write-Host ''
    Write-Host '  ctx chart'
    Write-Host '  ctx chart <project>'
    Write-Host '  ctx chart --set "`> new goal"'
    Write-Host '  ctx chart --write'
    Write-Host '  ctx chart --dock'
    exit 0
}

$resolved = $null
if ($ProjectOrScope) { $resolved = Resolve-CtxProjectByName $ProjectOrScope }
if (-not $resolved) { $resolved = Resolve-CtxProject }

if (-not $resolved.ProjectId) {
    $registry = Get-AtCtxRegistry
    $projects = if ($registry -and $registry.projects) { @($registry.projects.PSObject.Properties) } else { @() }
    Write-Host 'CTX HOME 1.0' -ForegroundColor Cyan
    Write-Host "@ home workspace ($($projects.Count) projects)"
    Write-Host '> personal context continuity'
    Write-Host ': no active project resolved'
    Write-Host '; run ctx register inside a project'
    Write-Host '? or use ctx chart <project-id>'
    if ($projects.Count -gt 0) {
        $preview = ($projects | Select-Object -First 5 | ForEach-Object { $_.Name }) -join ', '
        Write-Host "+ projects: $preview"
    } else {
        Write-Host '+ no registered projects yet'
    }
    Write-Host '~ ready'
    exit 0
}

Set-CtxEnvironment $resolved
$contextDir = $resolved.ContextDir
if (-not (Test-Path $contextDir)) { New-Item -ItemType Directory -Path $contextDir -Force | Out-Null }
$lines = Load-ChartLines -ContextDir $contextDir -ProjectId $resolved.ProjectId
$lines[1] = "@ $($resolved.ProjectId) ($(Get-Stats $contextDir))"

if ($Set) {
    $lines = Set-ChartField -Lines $lines -FieldSpec $Set -ProjectId $resolved.ProjectId -ContextDir $contextDir
    Save-ChartLines -ContextDir $contextDir -Lines $lines
}
if ($Write -or $Dock) { Save-ChartLines -ContextDir $contextDir -Lines $lines }
foreach ($line in $lines) { Write-Host $line }
$hint = Get-ScentHint -ProjectId $resolved.ProjectId
if ($hint) { Write-Host ("! {0}" -f $hint.signal) -ForegroundColor Yellow }
if ($Dock) {
    $historyFile = Join-Path $contextDir 'history.md'
    $goal = ($lines | Where-Object { $_ -match '^> ' } | Select-Object -First 1)
    $focus = ($lines | Where-Object { $_ -match '^: ' } | Select-Object -First 1)
    $next = ($lines | Where-Object { $_ -match '^; ' } | Select-Object -First 1)
    Add-Content $historyFile ("- $(Get-Date -Format 'yyyy-MM-dd HH:mm') :: $goal | $focus | $next")
    Write-Host ''
    Write-Host 'Docked.' -ForegroundColor Green
}
