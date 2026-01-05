#!/usr/bin/env pwsh
# ctx - Context navigation tool
# Usage: ./ctx <command> [args...]
#
# Commands are discovered from ctx-registry.json
# Missing commands return kit instructions for building them
# Agents extend this by adding commands to ./ctx-commands/

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RegistryPath = Join-Path $ScriptDir "ctx-registry.json"
$CommandsDir = Join-Path $ScriptDir "ctx-commands"
$KitsDir = Join-Path $ScriptDir "ctx-kits"

# Bootstrap: ensure registry exists
if (-not (Test-Path $RegistryPath)) {
    $timestamp = (Get-Date).ToString("o")
    @{
        meta = @{
            created = $timestamp
            description = "Context tool command registry. Agents may extend."
        }
        commands = @{}
    } | ConvertTo-Json -Depth 10 | Set-Content $RegistryPath
}

# No command: show help
if ($args.Count -eq 0) {
    Write-Host "ctx - Context navigation tool" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: ./ctx <command> [args...]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow

    # Parse registry
    $registry = Get-Content $RegistryPath | ConvertFrom-Json

    $registry.commands.PSObject.Properties | Sort-Object Name | ForEach-Object {
        $name = $_.Name
        $cmd = $_.Value
        $status = $cmd.status
        $desc = if ($cmd.description) { $cmd.description } else { "(no description)" }

        switch ($status) {
            "implemented" {
                Write-Host "  " -NoNewline
                Write-Host "[+] $name" -ForegroundColor Green -NoNewline
                Write-Host " - $desc" -ForegroundColor Gray
            }
            "kit" {
                Write-Host "  " -NoNewline
                Write-Host "[?] $name" -ForegroundColor Gray -NoNewline
                Write-Host " - $desc" -ForegroundColor Gray
            }
            "requested" {
                Write-Host "  " -NoNewline
                Write-Host "[ ] $name" -ForegroundColor Gray -NoNewline
                Write-Host " - $desc" -ForegroundColor Gray
            }
            default {
                Write-Host "  " -NoNewline
                Write-Host "[·] $name" -ForegroundColor Gray -NoNewline
                Write-Host " - $desc" -ForegroundColor Gray
            }
        }
    }

    Write-Host ""
    Write-Host "Legend: [+] implemented  [?] kit available  [ ] requested" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Try a command that doesn't exist to request it." -ForegroundColor Gray
    exit 0
}

$Command = $args[0]
$CommandArgs = $args[1..($args.Count - 1)]

# Check if command script exists (implemented) - try .ps1 first, then .sh
$ps1Path = Join-Path $CommandsDir "$Command.ps1"
$shPath = Join-Path $CommandsDir "$Command.sh"

if (Test-Path $ps1Path) {
    & pwsh -ExecutionPolicy Bypass -File $ps1Path @CommandArgs
    exit $LASTEXITCODE
}

if (Test-Path $shPath) {
    & bash $shPath @CommandArgs
    exit $LASTEXITCODE
}

# Check if kit exists
$kitPath = Join-Path $KitsDir "$Command.kit.md"
if (Test-Path $kitPath) {
    Write-Host "COMMAND NOT YET IMPLEMENTED: $Command" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A kit exists with instructions to build this command:" -ForegroundColor Cyan
    Write-Host "  $kitPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "--- KIT CONTENTS ---" -ForegroundColor Gray
    Get-Content $kitPath
    Write-Host "--- END KIT ---" -ForegroundColor Gray
    exit 0
}

# Check registry for requested status
$registry = Get-Content $RegistryPath | ConvertFrom-Json
$cmdInfo = $registry.commands.$Command

if ($cmdInfo -and $cmdInfo.status -eq "requested") {
    Write-Host "COMMAND REQUESTED BUT NOT YET BUILT: $Command" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To implement:" -ForegroundColor Cyan
    Write-Host "  1. Create script: ctx-commands/$Command.ps1" -ForegroundColor Gray
    Write-Host "  2. Or create kit: ctx-kits/$Command.kit.md" -ForegroundColor Gray
    exit 0
}

# Unknown command - register as requested
Write-Host "UNKNOWN COMMAND: $Command" -ForegroundColor Yellow
Write-Host ""
Write-Host "This command does not exist yet." -ForegroundColor Gray
Write-Host ""

# Add to registry
$timestamp = (Get-Date).ToString("o")
$user = if ($env:USER) { $env:USER } elseif ($env:USERNAME) { $env:USERNAME } else { "agent" }

$registry.commands | Add-Member -MemberType NoteProperty -Name $Command -Value @{
    status = "requested"
    requested_at = $timestamp
    requested_by = $user
    description = $null
} -Force

$registry | ConvertTo-Json -Depth 10 | Set-Content $RegistryPath

Write-Host "Added '$Command' to registry as REQUESTED." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps for an agent:" -ForegroundColor Yellow
Write-Host "  1. Decide what '$Command' should do" -ForegroundColor Gray
Write-Host "  2. Create ctx-kits/$Command.kit.md with build instructions" -ForegroundColor Gray
Write-Host "  3. Or implement directly in ctx-commands/$Command.ps1" -ForegroundColor Gray
