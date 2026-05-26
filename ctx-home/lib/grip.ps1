function Get-AtCtxRoot {
    return (Find-AtCtxDir)
}

function Get-GripDir {
    param([string]$WedgeId = 'home')
    return (Join-Path (Get-AtCtxRoot) "projects\$WedgeId")
}

function Get-GripPath {
    param([string]$WedgeId = 'home')
    return (Join-Path (Get-GripDir -WedgeId $WedgeId) 'grip.md')
}

function Read-Grip {
    param([string]$WedgeId = 'home')
    $p = Get-GripPath -WedgeId $WedgeId
    if (Test-Path $p) { return Get-Content $p -Raw }
    return $null
}

function Initialize-Grip {
    param([string]$WedgeId = 'home')
    $dir = Get-GripDir -WedgeId $WedgeId
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $p = Get-GripPath -WedgeId $WedgeId
    if (-not (Test-Path $p)) {
        $template = @"
# $WedgeId — grip

> Durable wedge memory for a long-running thread.
> Keep it compact. Crystallize older notes into history when it grows too large.

## Wedge

(What this named thread is for.)

## Active Focus

(What matters right now.)

## In-flight

(Partial work, drafts, experiments, open loops.)

## Open Questions

(Things the next session should investigate.)

## Recent Ledger

(Refresh with `ctx grip ledger`.)

## To Next Session

(What the next session should read first.)

## Notes

(Append-only scratch notes.)
"@
        Set-Content -Path $p -Value $template -Encoding UTF8
    }
    return $p
}

function Get-GripStats {
    param([string]$WedgeId = 'home')
    $p = Get-GripPath -WedgeId $WedgeId
    if (-not (Test-Path $p)) { return $null }
    $content = Get-Content $p -Raw
    $lines = ($content -split "`n").Count
    $chars = $content.Length
    $tokens = [int]($chars / 4)
    [PSCustomObject]@{ Path = $p; Lines = $lines; Chars = $chars; ApproxTokens = $tokens; Budget = 3000; BudgetUsedPct = [int](($tokens / 3000) * 100) }
}

function Append-GripNote {
    param([string]$WedgeId = 'home', [Parameter(Mandatory)][string]$Note)
    $p = Initialize-Grip -WedgeId $WedgeId
    $content = Get-Content $p -Raw
    $entry = "- [$(Get-Date -Format 'MM-dd HH:mm')] $Note"
    if ($content -match '(?s)(## Notes\s*\r?\n.*)$') {
        $newContent = $content -replace '(?s)## Notes\s*\r?\n.*$', ($Matches[0].TrimEnd() + "`n$entry`n")
    } else {
        $newContent = $content.TrimEnd() + "`n`n## Notes`n`n$entry`n"
    }
    Set-Content $p -Value $newContent -Encoding UTF8
}

function Set-GripSection {
    param([string]$WedgeId = 'home', [Parameter(Mandatory)][string]$Section, [Parameter(Mandatory)][string]$Body)
    $p = Initialize-Grip -WedgeId $WedgeId
    $content = Get-Content $p -Raw
    $esc = [regex]::Escape($Section)
    $pattern = "(?ms)^(##\s+$esc)\s*\r?\n.*?(?=^##\s|\z)"
    if ($content -match $pattern) {
        $content = [regex]::Replace($content, $pattern, "`$1`n`n$Body`n`n")
    } else {
        $content = $content.TrimEnd() + "`n`n## $Section`n`n$Body`n"
    }
    Set-Content $p -Value $content -Encoding UTF8
}

function Get-RecentLedgerSummary {
    param([int]$N = 5)
    $historyDir = Join-Path (Get-AtCtxRoot) 'history'
    if (-not (Test-Path $historyDir)) { return @() }
    $entries = @()
    Get-ChildItem $historyDir -Filter 'sessions-*.jsonl' -ErrorAction SilentlyContinue | ForEach-Object {
        Get-Content $_.FullName -ErrorAction SilentlyContinue | ForEach-Object {
            try { $entries += ($_ | ConvertFrom-Json) } catch {}
        }
    }
    return @($entries | Sort-Object absorbed_at -Descending | Select-Object -First $N)
}
