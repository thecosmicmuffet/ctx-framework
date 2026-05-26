#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0)][string]$Subcommand,
    [Parameter(Position = 1)][string]$Signal,
    [double]$Salience = 0.5,
    [string]$Affordance = 'read',
    [string]$Project,
    [int]$TTL = 12,
    [switch]$ShowExpired,
    [switch]$AsJson,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')

if ($Help -or -not $Subcommand) {
    Write-Host 'ctx scent - lightweight cross-session signals'
    Write-Host ''
    Write-Host '  ctx scent emit <signal> [--salience N] [--ttl H]'
    Write-Host '  ctx scent ask <question> [--salience N] [--ttl H]'
    Write-Host '  ctx scent read [--show-expired]'
    Write-Host '  ctx scent clear'
    exit 0
}

$atCtx = Find-AtCtxDir
if (-not (Test-Path $atCtx)) { New-Item -ItemType Directory -Path $atCtx -Force | Out-Null }
$scentFile = Join-Path $atCtx 'scent.jsonl'
$resolved = Resolve-CtxProject
$effectiveProject = if ($Project) { $Project } elseif ($resolved.ProjectId) { $resolved.ProjectId } else { 'global' }

switch ($Subcommand.ToLower()) {
    'emit' {
        if (-not $Signal) { throw 'Usage: ctx scent emit <signal>' }
        $entry = [ordered]@{
            timestamp = (Get-Date -Format 'o')
            project = $effectiveProject
            signal = $Signal
            salience = [Math]::Max(0.0, [Math]::Min(1.0, $Salience))
            affordance = $Affordance
            ttl_hours = $TTL
            expires_at = (Get-Date).AddHours($TTL).ToString('o')
        }
        Add-Content $scentFile (($entry | ConvertTo-Json -Compress))
        Write-Host "SCENT: $Signal" -ForegroundColor Cyan
    }
    'ask' {
        if (-not $Signal) { throw 'Usage: ctx scent ask <question>' }
        $entry = [ordered]@{
            timestamp = (Get-Date -Format 'o')
            project = $effectiveProject
            signal = $Signal
            mood = 'question'
            salience = [Math]::Max(0.0, [Math]::Min(1.0, $Salience))
            affordance = 'consider'
            ttl_hours = $TTL
            expires_at = (Get-Date).AddHours($TTL).ToString('o')
        }
        Add-Content $scentFile (($entry | ConvertTo-Json -Compress))
        Write-Host "SCENT ? $Signal" -ForegroundColor Yellow
    }
    'read' {
        if (-not (Test-Path $scentFile)) { Write-Host 'No scent trails.' -ForegroundColor Gray; exit 0 }
        $now = Get-Date
        $items = @()
        Get-Content $scentFile -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $item = $_ | ConvertFrom-Json
                $expired = [datetime]$item.expires_at -lt $now
                if ($expired -and -not $ShowExpired) { return }
                $item | Add-Member -NotePropertyName is_expired -NotePropertyValue $expired -Force
                $items += $item
            } catch {}
        }
        $items = @($items | Sort-Object { -[double]$_.salience })
        if ($AsJson) { $items | ConvertTo-Json -Depth 4; exit 0 }
        if ($items.Count -eq 0) { Write-Host 'No active scent trails.' -ForegroundColor Gray; exit 0 }
        Write-Host 'SCENT TRAILS' -ForegroundColor Cyan
        Write-Host ''
        foreach ($item in $items) {
            $prefix = if ($item.PSObject.Properties['mood'] -and $item.mood -eq 'question') { '? ' } else { '' }
            $suffix = if ($item.is_expired) { ' [expired]' } else { '' }
            Write-Host "  $prefix$($item.signal)$suffix" -ForegroundColor $(if ([double]$item.salience -ge 0.7) { 'Red' } elseif ([double]$item.salience -ge 0.4) { 'Yellow' } else { 'Gray' })
            Write-Host "       $($item.project) | $($item.affordance)" -ForegroundColor DarkGray
        }
    }
    'clear' {
        if (-not (Test-Path $scentFile)) { Write-Host 'No scent trails to clear.' -ForegroundColor Gray; exit 0 }
        $now = Get-Date
        $kept = @()
        $removed = 0
        Get-Content $scentFile -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                $item = $_ | ConvertFrom-Json
                if ([datetime]$item.expires_at -ge $now) { $kept += $_ } else { $removed++ }
            } catch { $removed++ }
        }
        if ($kept.Count -gt 0) { $kept | Set-Content $scentFile } elseif (Test-Path $scentFile) { Remove-Item $scentFile -Force }
        Write-Host "Cleared $removed expired scent trail(s)." -ForegroundColor Green
    }
    default { throw 'Use: emit, ask, read, clear' }
}
