#!/usr/bin/env pwsh
# ctx home edition — framework integrity validation
# Run from ctx-home/ root

param(
    [switch]$Quiet,     # suppress passing tests
    [switch]$Json       # emit JSON summary instead of human output
)

$ErrorActionPreference = 'Stop'

$frameworkPath = $PSScriptRoot
$commandsDir   = Join-Path $frameworkPath "commands"
$libDir        = Join-Path $frameworkPath "lib"
$kitsDir       = Join-Path $frameworkPath "kits"
$registryFile  = Join-Path $frameworkPath "registry.json"

$passed  = 0
$failed  = 0
$warned  = 0
$details = @()

function Pass([string]$Msg) {
    $script:passed++
    if (-not $Quiet) { Write-Host "  ✅ $Msg" -ForegroundColor Green }
    $script:details += [ordered]@{ status = "pass"; message = $Msg }
}
function Fail([string]$Msg) {
    $script:failed++
    Write-Host "  ❌ $Msg" -ForegroundColor Red
    $script:details += [ordered]@{ status = "fail"; message = $Msg }
}
function Warn([string]$Msg) {
    $script:warned++
    Write-Host "  ⚠️  $Msg" -ForegroundColor Yellow
    $script:details += [ordered]@{ status = "warn"; message = $Msg }
}

if (-not $Json) {
    Write-Host "=== ctx home Validation ===" -ForegroundColor Cyan
    Write-Host ""
}

# ── 1. Infrastructure files ─────────────────────────────────────────
if (-not $Json) { Write-Host "1. Infrastructure" -ForegroundColor Yellow }

$infrastructure = @("ctx.ps1", "ctx", "bootstrap.ps1", "registry.json", "SKILL.md", "HOME-README.md")
foreach ($f in $infrastructure) {
    $p = Join-Path $frameworkPath $f
    if (Test-Path $p) { Pass "exists: $f" } else { Fail "missing: $f" }
}

foreach ($subdir in @("commands", "lib", "kits")) {
    $p = Join-Path $frameworkPath $subdir
    if (Test-Path $p) { Pass "dir exists: $subdir/" } else { Fail "dir missing: $subdir/" }
}

if (-not $Json) { Write-Host "" }

# ── 2. Registry integrity ───────────────────────────────────────────
if (-not $Json) { Write-Host "2. Registry integrity" -ForegroundColor Yellow }

$registry = $null
try {
    $registry = Get-Content $registryFile -Raw | ConvertFrom-Json
    Pass "registry.json parses as valid JSON"
} catch {
    Fail "registry.json is invalid JSON: $_"
}

if ($registry) {
    if ($registry.meta) { Pass "registry has meta section" }
    else { Fail "registry missing meta section" }

    if ($registry.commands) { Pass "registry has commands section" }
    else { Fail "registry missing commands section" }
}

if (-not $Json) { Write-Host "" }

# ── 3. Registry ↔ commands consistency ───────────────────────────────
if (-not $Json) { Write-Host "3. Registry ↔ commands" -ForegroundColor Yellow }

if ($registry -and $registry.commands) {
    $regEntries = $registry.commands.PSObject.Properties

    # Every implemented entry must have a .ps1
    $implemented = $regEntries | Where-Object { $_.Value.status -eq 'implemented' }
    foreach ($cmd in $implemented) {
        $ps1 = Join-Path $commandsDir "$($cmd.Name).ps1"
        if (Test-Path $ps1) { Pass "implemented → file: $($cmd.Name).ps1" }
        else { Fail "registered as implemented but no file: $($cmd.Name).ps1" }
    }

    # Every kit entry should have a kit file
    $kitEntries = $regEntries | Where-Object { $_.Value.status -eq 'kit' }
    foreach ($cmd in $kitEntries) {
        $kitFile = Join-Path $kitsDir "$($cmd.Name).kit.md"
        if (Test-Path $kitFile) { Pass "kit → spec: $($cmd.Name).kit.md" }
        else { Warn "registered as kit but no spec: $($cmd.Name).kit.md" }
    }

    # Commands on disk but not in registry
    if (Test-Path $commandsDir) {
        $diskCmds = (Get-ChildItem $commandsDir -Filter "*.ps1" -ErrorAction SilentlyContinue).BaseName
        $regNames = @($regEntries.Name)
        foreach ($dc in $diskCmds) {
            if ($dc -notin $regNames) {
                Warn "on disk but unregistered: $dc.ps1"
            }
        }
    }
}

if (-not $Json) { Write-Host "" }

# ── 4. Syntax check ─────────────────────────────────────────────────
if (-not $Json) { Write-Host "4. Syntax check" -ForegroundColor Yellow }

$ps1Files = @()
if (Test-Path $commandsDir) {
    $ps1Files += Get-ChildItem $commandsDir -Filter "*.ps1" -ErrorAction SilentlyContinue
}
if (Test-Path $libDir) {
    $ps1Files += Get-ChildItem $libDir -Filter "*.ps1" -ErrorAction SilentlyContinue
}
$routerFile = Join-Path $frameworkPath "ctx.ps1"
if (Test-Path $routerFile) {
    $ps1Files += Get-Item $routerFile
}

foreach ($f in $ps1Files) {
    $tokens = $null; $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $f.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -eq 0) {
        Pass "syntax ok: $($f.Name)"
    } else {
        foreach ($e in $parseErrors) {
            Fail "syntax error in $($f.Name): $($e.Message) (line $($e.Extent.StartLineNumber))"
        }
    }
}

if (-not $Json) { Write-Host "" }

# ── 5. Core lib files ───────────────────────────────────────────────
if (-not $Json) { Write-Host "5. Core libraries" -ForegroundColor Yellow }

$coreLibs = @("resolve.ps1", "grip.ps1", "config.ps1")
foreach ($lib in $coreLibs) {
    $p = Join-Path $libDir $lib
    if (Test-Path $p) { Pass "lib: $lib" } else { Fail "missing lib: $lib" }
}

if (-not $Json) { Write-Host "" }

# ── 6. Router smoke test ────────────────────────────────────────────
if (-not $Json) { Write-Host "6. Router smoke test" -ForegroundColor Yellow }

try {
    $output = & "$frameworkPath\ctx.ps1" 2>&1 | Out-String
    if ($output -match 'ctx' -or $LASTEXITCODE -eq 0) {
        Pass "router executes and produces output"
    } else {
        Warn "router executed but output unexpected"
    }
} catch {
    Fail "router threw exception: $($_.Exception.Message)"
}

if (-not $Json) { Write-Host "" }

# ── Summary ─────────────────────────────────────────────────────────
$total = $passed + $failed + $warned

if ($Json) {
    [ordered]@{
        passed  = $passed
        failed  = $failed
        warned  = $warned
        total   = $total
        ok      = ($failed -eq 0)
        details = $details
    } | ConvertTo-Json -Depth 3
} else {
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    Write-Host "  $passed passed, $failed failed, $warned warnings ($total checks)" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

    if ($failed -eq 0 -and $warned -eq 0) {
        Write-Host "  Framework integrity confirmed." -ForegroundColor Green
    } elseif ($failed -eq 0) {
        Write-Host "  No failures. Warnings indicate drift worth reviewing." -ForegroundColor Yellow
    } else {
        Write-Host "  Failures need attention." -ForegroundColor Red
    }
}

exit $(if ($failed -eq 0) { 0 } else { 1 })
