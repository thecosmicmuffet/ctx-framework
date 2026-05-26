#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [Parameter(Position=0)][string]$Token1,
    [Parameter(Position=1)][string]$Token2,
    [Parameter(Position=2)][string]$Token3,
    [string]$Wedge,
    [switch]$Json
)

if (-not $Wedge) { $Wedge = if ($env:CTX_PROJECT_ID) { $env:CTX_PROJECT_ID } else { 'home' } }
. (Join-Path $PSScriptRoot '..' 'lib' 'grip.ps1')

function Show-Grip {
    $content = Read-Grip -WedgeId $Wedge
    if ($Json) {
        @{ wedge = $Wedge; content = $content; stats = (Get-GripStats -WedgeId $Wedge) } | ConvertTo-Json -Depth 5
        return
    }
    if (-not $content) { Write-Host "No grip for '$Wedge'. Run: ctx grip init" -ForegroundColor Yellow; return }
    $stats = Get-GripStats -WedgeId $Wedge
    Write-Host "GRIP: $($stats.Path)" -ForegroundColor Cyan
    Write-Host "  ~$($stats.ApproxTokens) tokens ($($stats.BudgetUsedPct)% of 3k)" -ForegroundColor DarkGray
    Write-Host ''
    Write-Host $content
}

switch ($Token1) {
    $null { Show-Grip }
    'show' { Show-Grip }
    'init' { Write-Host (Initialize-Grip -WedgeId $Wedge) -ForegroundColor Green }
    'note' { Append-GripNote -WedgeId $Wedge -Note $Token2; Write-Host 'Note appended.' -ForegroundColor Green }
    'set' { Set-GripSection -WedgeId $Wedge -Section $Token2 -Body $Token3; Write-Host 'Section updated.' -ForegroundColor Green }
    'stats' { Get-GripStats -WedgeId $Wedge | Format-List }
    'ledger' {
        $entries = Get-RecentLedgerSummary -N 5
        $body = ($entries | ForEach-Object { "- $($_.absorbed_at) $($_.session_id)" }) -join "`n"
        Set-GripSection -WedgeId $Wedge -Section 'Recent Ledger' -Body $body
        Write-Host 'Ledger refreshed.' -ForegroundColor Green
    }
    default { Write-Host 'Use: show, init, note, set, stats, ledger' -ForegroundColor Yellow }
}
