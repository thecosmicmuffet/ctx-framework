#!/usr/bin/env pwsh
param(
    [Parameter(Position=0)][string]$Command = 'assess',
    [Parameter(Position=1)][string]$Target = '',
    [switch]$Help
)

$base = if ($env:CTX_CONTEXT_DIR) { $env:CTX_CONTEXT_DIR } else { Join-Path (Get-Location) '.ctx-data' }
$FEAR_DIR = Join-Path $base 'fear'
$QUEUE_FILE = Join-Path $FEAR_DIR 'queue.json'
$SNAPSHOTS_DIR = Join-Path $FEAR_DIR 'snapshots'
$HANDOFFS_DIR = Join-Path $FEAR_DIR 'handoffs'

function Ensure-Fear {
    foreach ($dir in @($FEAR_DIR, $SNAPSHOTS_DIR, $HANDOFFS_DIR)) {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    }
    if (-not (Test-Path $QUEUE_FILE)) { @{ active=@(); rotation_history=@() } | ConvertTo-Json -Depth 10 | Set-Content $QUEUE_FILE -Encoding UTF8 }
}

if ($Help) {
    Write-Host 'ctx fear - rotate perspective when work becomes recursive'
    Write-Host ''
    Write-Host '  ctx fear assess'
    Write-Host '  ctx fear invoke <thread>'
    Write-Host '  ctx fear rotate <other-thread>'
    Write-Host '  ctx fear reground <thread>'
    exit 0
}

Ensure-Fear

switch ($Command.ToLower()) {
    'assess' {
        $queue = Get-Content $QUEUE_FILE -Raw | ConvertFrom-Json
        Write-Host 'FEAR QUEUE' -ForegroundColor Cyan
        Write-Host ''
        foreach ($item in $queue.active) { Write-Host "  [$($item.id)] priority=$($item.priority) rotations=$($item.rotation_count)" -ForegroundColor Gray }
        if (@($queue.active).Count -eq 0) { Write-Host '  queue is empty' -ForegroundColor DarkGray }
    }
    'invoke' {
        if (-not $Target) { throw 'Usage: ctx fear invoke <thread>' }
        $queue = Get-Content $QUEUE_FILE -Raw | ConvertFrom-Json
        $snapshot = Join-Path $SNAPSHOTS_DIR ("$Target-$(Get-Date -Format 'yyyyMMdd-HHmmss').json")
        @{ meta=@{ thread=$Target; timestamp=(Get-Date -Format 'o') }; state=@{ knot='unknown'; notes='' } } | ConvertTo-Json -Depth 10 | Set-Content $snapshot -Encoding UTF8
        if (-not ($queue.active | Where-Object { $_.id -eq $Target })) {
            $queue.active += [PSCustomObject]@{ id=$Target; priority=1; rotation_count=0; added=(Get-Date -Format 'o') }
            $queue | ConvertTo-Json -Depth 10 | Set-Content $QUEUE_FILE -Encoding UTF8
        }
        Write-Host "Invoked fear for $Target" -ForegroundColor Yellow
        Write-Host "  Snapshot: $snapshot" -ForegroundColor Gray
    }
    'rotate' {
        if (-not $Target) { throw 'Usage: ctx fear rotate <other-thread>' }
        $queue = Get-Content $QUEUE_FILE -Raw | ConvertFrom-Json
        $queue.rotation_history += [PSCustomObject]@{ timestamp=(Get-Date -Format 'o'); to=$Target }
        $queue | ConvertTo-Json -Depth 10 | Set-Content $QUEUE_FILE -Encoding UTF8
        $handoff = Join-Path $HANDOFFS_DIR ("rotation-$(Get-Date -Format 'yyyyMMdd-HHmmss').md")
        Set-Content $handoff "# Rotation to $Target`n`nWhy rotate? What changed? What should the next pass test?" -Encoding UTF8
        Write-Host "Rotated toward $Target" -ForegroundColor Green
        Write-Host "  Handoff: $handoff" -ForegroundColor Gray
    }
    'reground' {
        if (-not $Target) { throw 'Usage: ctx fear reground <thread>' }
        Write-Host "Reground in $Target" -ForegroundColor Green
        Write-Host 'Return with a different framing, not a longer repetition.' -ForegroundColor Gray
    }
    default { throw 'Use: assess, invoke, rotate, reground' }
}
