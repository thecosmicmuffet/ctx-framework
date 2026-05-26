#!/usr/bin/env pwsh
# ctx plan - Command discovery with research tree visualization
# Shows implemented commands, kit suggestions ordered by dependency,
# and what implementing each kit unlocks.

param(
    [switch]$Help,
    [switch]$TreeOnly,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"

if ($Help) {
    Write-Host "ctx plan - Command discovery and research tree"
    Write-Host ""
    Write-Host "  ctx plan         show commands grouped by status + research tree"
    Write-Host "  ctx plan --tree  show dependency tree only"
    Write-Host ""
    exit 0
}

# Load registry
$registryPath = Join-Path $PSScriptRoot ".." "registry.json"
if (-not (Test-Path $registryPath)) {
    Write-Host "No registry.json found." -ForegroundColor Red
    exit 1
}
$registry = Get-Content $registryPath -Raw | ConvertFrom-Json

# --- Collect commands by status ---
$implemented = @()
$kits = @()
$requested = @()

foreach ($prop in $registry.commands.PSObject.Properties) {
    $cmd = $prop.Value
    $entry = [PSCustomObject]@{
        Name   = $prop.Name
        Token  = if ($cmd.token) { $cmd.token } else { "?" }
        Desc   = if ($cmd.description) { $cmd.description } else { "" }
        Status = $cmd.status
    }
    switch ($cmd.status) {
        "implemented" { $implemented += $entry }
        "kit"         { $kits += $entry }
        "requested"   { $requested += $entry }
    }
}

if (-not $TreeOnly) {
    # --- Show implemented commands ---
    Write-Host "IMPLEMENTED ($($implemented.Count))" -ForegroundColor Green
    foreach ($cmd in ($implemented | Sort-Object Token, Name)) {
        $tokenDisplay = $cmd.Token.PadRight(2)
        $nameDisplay = $cmd.Name.PadRight(14)
        Write-Host "  $tokenDisplay $nameDisplay $($cmd.Desc)" -ForegroundColor Gray
    }
    Write-Host ""

    # --- Show kits (ordered by research tree — what to build next) ---
    Write-Host "KITS — ready to implement ($($kits.Count))" -ForegroundColor Yellow

    # Build dependency order from research tree
    $tree = @{}
    if ($registry.meta.research_tree -and $registry.meta.research_tree.paths) {
        foreach ($edge in $registry.meta.research_tree.paths) {
            if (-not $tree.ContainsKey($edge.to)) { $tree[$edge.to] = @() }
            $tree[$edge.to] += $edge.from
        }
    }

    # Kits with all dependencies implemented come first (unlocked)
    $unlocked = @()
    $blocked = @()
    foreach ($kit in ($kits | Sort-Object Token, Name)) {
        $deps = $tree[$kit.Name]
        $allDepsImpl = $true
        $missingDeps = @()
        if ($deps) {
            foreach ($dep in $deps) {
                $depCmd = $registry.commands.PSObject.Properties | Where-Object { $_.Name -eq $dep }
                if (-not $depCmd -or $depCmd.Value.status -ne "implemented") {
                    $allDepsImpl = $false
                    $missingDeps += $dep
                }
            }
        }
        if ($allDepsImpl) {
            $unlocked += [PSCustomObject]@{ Kit = $kit; Missing = @() }
        } else {
            $blocked += [PSCustomObject]@{ Kit = $kit; Missing = $missingDeps }
        }
    }

    if ($unlocked.Count -gt 0) {
        Write-Host "  UNLOCKED (dependencies met):" -ForegroundColor Green
        foreach ($u in $unlocked) {
            $k = $u.Kit
            $tokenDisplay = $k.Token.PadRight(2)
            $nameDisplay = $k.Name.PadRight(14)
            Write-Host "  $tokenDisplay $nameDisplay $($k.Desc)" -ForegroundColor White
        }
    }
    if ($blocked.Count -gt 0) {
        Write-Host "  BLOCKED (needs implementation first):" -ForegroundColor DarkGray
        foreach ($b in $blocked) {
            $k = $b.Kit
            $tokenDisplay = $k.Token.PadRight(2)
            $nameDisplay = $k.Name.PadRight(14)
            $missingStr = ($b.Missing -join ", ")
            Write-Host "  $tokenDisplay $nameDisplay needs: $missingStr" -ForegroundColor DarkGray
        }
    }
    Write-Host ""

    if ($requested.Count -gt 0) {
        Write-Host "REQUESTED ($($requested.Count))" -ForegroundColor DarkGray
        foreach ($cmd in ($requested | Sort-Object Name)) {
            Write-Host "  ?  $($cmd.Name)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }
}

# --- Research tree visualization ---
Write-Host "RESEARCH TREE" -ForegroundColor Cyan
if ($registry.meta.research_tree -and $registry.meta.research_tree.paths) {
    # Group edges by 'from' to show what each implementation unlocks
    $unlocks = @{}
    foreach ($edge in $registry.meta.research_tree.paths) {
        if (-not $unlocks.ContainsKey($edge.from)) { $unlocks[$edge.from] = @() }
        $unlocks[$edge.from] += [PSCustomObject]@{ To = $edge.to; Relation = $edge.relation }
    }

    foreach ($from in ($unlocks.Keys | Sort-Object)) {
        $fromCmd = $registry.commands.PSObject.Properties | Where-Object { $_.Name -eq $from }
        $status = if ($fromCmd) {
            switch ($fromCmd.Value.status) {
                "implemented" { "[+]" }
                "kit"         { "[?]" }
                default       { "[ ]" }
            }
        } else { "[ ]" }

        $statusColor = switch ($status) {
            "[+]" { "Green" }
            "[?]" { "Yellow" }
            default { "Gray" }
        }

        Write-Host "  $status " -ForegroundColor $statusColor -NoNewline
        Write-Host "$from" -ForegroundColor White
        foreach ($target in $unlocks[$from]) {
            Write-Host "       +-- $($target.To): $($target.Relation)" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  (no research tree defined in registry.json)" -ForegroundColor DarkGray
}
Write-Host ""
Write-Host "Legend: [+] implemented  [?] kit available  [ ] requested" -ForegroundColor DarkGray
