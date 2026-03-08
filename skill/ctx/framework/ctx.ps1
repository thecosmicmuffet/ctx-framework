#!/usr/bin/env pwsh
# ctx.ps1 - Context navigation tool (PowerShell edition)
# Usage: .\ctx.ps1 <command> [args...]
#
# Commands are discovered from registry.json
# Missing commands return kit instructions for building them
# Agents extend this by adding commands to ./commands/

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AllArgs
)

$ErrorActionPreference = 'Stop'

$Command = $null
$Arguments = @()

if ($AllArgs -and $AllArgs.Count -gt 0) {
    $Command = $AllArgs[0]
    if ($AllArgs.Count -gt 1) {
        $Arguments = $AllArgs[1..($AllArgs.Count - 1)]
    }
}

# Alias mapping for common variants (prevents "decisions" vs "decision" confusion)
$CommandAliases = @{
    "decisions" = "decision"
    "states"    = "state"
    "todo"      = "todos"
    "plans"     = "plan"
    "finds"     = "find"
    "searches"  = "search"
    "stakes"    = "stake"
}

if ($Command -and $CommandAliases.ContainsKey($Command)) {
    $Command = $CommandAliases[$Command]
}

# Bootstrap: Find CTX_HOME
function Find-CtxHome {
    # 1. CTX_HOME environment variable
    if ($env:CTX_HOME -and (Test-Path "$env:CTX_HOME\lib\core.sh")) {
        return $env:CTX_HOME
    }

    # 2. Script location (for in-tree usage)
    $scriptDir = Split-Path -Parent $MyInvocation.ScriptName
    if (Test-Path "$scriptDir\lib\core.sh") {
        return $scriptDir
    }

    # 3. User installation
    $userCtx = Join-Path $HOME ".ctx"
    if (Test-Path "$userCtx\lib\core.sh") {
        return $userCtx
    }

    # 4. Search upward from PWD
    $dir = Get-Location
    while ($dir) {
        $testPath = Join-Path $dir "ctx\lib\core.sh"
        if (Test-Path $testPath) {
            return Join-Path $dir "ctx"
        }
        $parent = Split-Path -Parent $dir
        if ($parent -eq $dir) { break }
        $dir = $parent
    }

    return $null
}

$CtxHome = Find-CtxHome
if (-not $CtxHome) {
    Write-Error "Error: ctx not found. Set CTX_HOME or run from ctx directory."
    exit 1
}

$env:CTX_HOME = $CtxHome
$RegistryPath = Join-Path $CtxHome "registry.json"
$CommandsDir = Join-Path $CtxHome "commands"
$KitsDir = Join-Path $CtxHome "kits"

# Path Resolution: Load configuration if it exists
$ConfigPath = $null
$LocationContext = $null
$ShowLocationHeader = $true  # Default: show header until agent is confident

# Search for .ctxconfig up the directory tree
$SearchDir = Get-Location
while ($SearchDir) {
    $TestPath = Join-Path $SearchDir ".ctxconfig"
    if (Test-Path $TestPath) {
        $ConfigPath = $TestPath
        try {
            $LocationContext = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            break
        } catch {
            Write-Warning "Found .ctxconfig but failed to parse: $TestPath"
        }
    }
    $Parent = Split-Path -Parent $SearchDir
    if ($Parent -eq $SearchDir) { break }  # Reached root
    $SearchDir = $Parent
}

# Resolve path variables if we have location context
function Resolve-CtxPath {
    param([string]$Path)
    if (-not $LocationContext -or -not $Path) { return $Path }
    
    $resolved = $Path
    if ($LocationContext.projects -and $LocationContext.current_project) {
        $project = $LocationContext.projects.($LocationContext.current_project)
        if ($project) {
            # Resolve in order: git_root first, then project_root (which may contain [git])
            $resolved = $resolved -replace '\[git\]', $project.git_root
            
            # Resolve project_root (may itself contain [git])
            $projectRoot = $project.project_root -replace '\[git\]', $project.git_root
            $resolved = $resolved -replace '\[project_root\]', $projectRoot
            $resolved = $resolved -replace '\[project\]', $projectRoot  # Legacy support
            
            # Resolve other paths
            $resolved = $resolved -replace '\[context\]', $project.context_dir
            $resolved = $resolved -replace '\[framework\]', $project.framework_dir
        }
    }
    return $resolved
}

# Set environment variables for commands to use
if ($LocationContext -and $LocationContext.current_project) {
    $project = $LocationContext.projects.($LocationContext.current_project)
    if ($project) {
        $env:CTX_PROJECT_NAME = $LocationContext.current_project
        $env:CTX_GIT_ROOT = $project.git_root
        $env:CTX_PROJECT_ROOT = Resolve-CtxPath $project.project_root
        $env:CTX_CONTEXT_DIR = Resolve-CtxPath $project.context_dir
        $env:CTX_FRAMEWORK_DIR = Resolve-CtxPath $project.framework_dir
    }
}

# Bootstrap: ensure registry exists
if (-not (Test-Path $RegistryPath)) {
    $bootstrapRegistry = @{
        meta = @{
            created = (Get-Date -Format "o")
            description = "Context tool command registry. Agents may extend."
        }
        commands = @{}
    }
    $bootstrapRegistry | ConvertTo-Json -Depth 10 | Set-Content $RegistryPath
}

# Load registry
$registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json

# No command: show help
if (-not $Command) {
    Write-Host "ctx - Universal context navigation" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\ctx.ps1 <command> [args...]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow
    
    $commands = $registry.commands.PSObject.Properties | Sort-Object Name
    foreach ($cmd in $commands) {
        $name = $cmd.Name
        $status = $cmd.Value.status
        $desc = if ($cmd.Value.description) { $cmd.Value.description } else { "(no description)" }
        
        $indicator = switch ($status) {
            "implemented" { "[+]"; $color = "Green" }
            "kit"         { "[?]"; $color = "Gray" }
            "requested"   { "[ ]"; $color = "Gray" }
            default       { "[·]"; $color = "Gray" }
        }
        
        Write-Host "  " -NoNewline
        Write-Host "$indicator $name" -ForegroundColor $color -NoNewline
        Write-Host " - $desc" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Legend: [+] implemented  [?] kit available  [ ] requested" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Try a command that doesn't exist to request it." -ForegroundColor Gray
    exit 0
}

# Show location header if enabled (suppressed if --quiet flag present)
$ShowHeader = $ShowLocationHeader -and ($Arguments -notcontains '--quiet') -and ($Arguments -notcontains '-q')
if ($ShowHeader -and $LocationContext) {
    $gitRoot = if ($env:CTX_GIT_ROOT) { $env:CTX_GIT_ROOT } else { "unknown" }
    $ctxDir = if ($env:CTX_CONTEXT_DIR) { $env:CTX_CONTEXT_DIR -replace [regex]::Escape($gitRoot), "[git]" } else { "unknown" }
    $cmdStatus = "unknown"
    
    # Check command status
    $ps1Exists = Test-Path (Join-Path $CommandsDir "$Command.ps1")
    $shExists = Test-Path (Join-Path $CommandsDir "$Command.sh")
    $kitExists = Test-Path (Join-Path $KitsDir "$Command.kit.md")
    
    if ($ps1Exists -or $shExists) {
        $cmdStatus = "exists"
    } elseif ($kitExists) {
        $cmdStatus = "kit"
    } else {
        $cmdStatus = "unknown"
    }
    
    Write-Host "[git:$gitRoot ctx:$ctxDir cmd:$Command`:$cmdStatus]" -ForegroundColor DarkGray
    Write-Host ([string]::new('─', 60)) -ForegroundColor DarkGray
}

# Check if PowerShell command script exists (implemented)
$ps1Script = Join-Path $CommandsDir "$Command.ps1"
if (Test-Path $ps1Script) {
    # Build argument string and invoke with Invoke-Expression for proper parameter handling
    # Convert --param to -Param for PowerShell compatibility
    if ($Arguments.Count -gt 0) {
        $argString = ($Arguments | ForEach-Object { 
            if ($_ -match '^--(.+)') {
                # Convert --param to -Param
                "-$($matches[1])"
            } elseif ($_ -match '^-') {
                $_
            } else {
                "'$_'"
            }
        }) -join ' '
        Invoke-Expression "& '$ps1Script' $argString"
    } else {
        & $ps1Script
    }
    exit $LASTEXITCODE
}

# Check if bash script exists (for cross-platform compatibility)
$shScript = Join-Path $CommandsDir "$Command.sh"
if (Test-Path $shScript) {
    # Try to execute with bash if available
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        bash $shScript @Arguments
        exit $LASTEXITCODE
    } else {
        Write-Host "COMMAND IMPLEMENTED IN BASH ONLY: $Command" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This command exists as a bash script but bash is not available." -ForegroundColor Gray
        Write-Host "Script location: $shScript" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Options:" -ForegroundColor Cyan
        Write-Host "  1. Install WSL/Git Bash to run .sh scripts" -ForegroundColor Gray
        Write-Host "  2. Create PowerShell version: commands/$Command.ps1" -ForegroundColor Gray
        exit 1
    }
}

# Check if kit exists
$kitFile = Join-Path $KitsDir "$Command.kit.md"
if (Test-Path $kitFile) {
    Write-Host "COMMAND NOT YET IMPLEMENTED: $Command" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "A kit exists with instructions to build this command:" -ForegroundColor Cyan
    Write-Host "  $kitFile" -ForegroundColor Gray
    Write-Host ""
    Write-Host "--- KIT CONTENTS ---" -ForegroundColor Gray
    Get-Content $kitFile | Write-Host
    Write-Host "--- END KIT ---" -ForegroundColor Gray
    exit 0
}

# Check registry for requested status
$commandStatus = $registry.commands.PSObject.Properties | Where-Object { $_.Name -eq $Command }
if ($commandStatus -and $commandStatus.Value.status -eq "requested") {
    Write-Host "COMMAND REQUESTED BUT NOT YET BUILT: $Command" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To implement:" -ForegroundColor Cyan
    Write-Host "  1. Create script: commands/$Command.ps1" -ForegroundColor Gray
    Write-Host "  2. Or create kit: kits/$Command.kit.md" -ForegroundColor Gray
    exit 0
}

# Unknown command - register as requested
Write-Host "UNKNOWN COMMAND: $Command" -ForegroundColor Yellow
Write-Host ""
Write-Host "This command does not exist yet." -ForegroundColor Gray
Write-Host ""

# Add to registry
$timestamp = Get-Date -Format "o"
$user = if ($env:USERNAME) { $env:USERNAME } else { "agent" }

if (-not $registry.commands.PSObject.Properties.Name -contains $Command) {
    $registry.commands | Add-Member -NotePropertyName $Command -NotePropertyValue ([PSCustomObject]@{
        status = "requested"
        requested_at = $timestamp
        requested_by = $user
        description = $null
    })
    
    $registry | ConvertTo-Json -Depth 10 | Set-Content $RegistryPath
    Write-Host "Added '$Command' to registry as REQUESTED." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Next steps for an agent:" -ForegroundColor Yellow
Write-Host "  1. Decide what '$Command' should do" -ForegroundColor Gray
Write-Host "  2. Create kits/$Command.kit.md with build instructions" -ForegroundColor Gray
Write-Host "  3. Or implement directly in commands/$Command.ps1" -ForegroundColor Gray
