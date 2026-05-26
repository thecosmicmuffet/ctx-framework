#!/usr/bin/env pwsh
param(
    [Parameter(Position = 0)][string]$Action = 'list',
    [Parameter(Position = 1)][string]$Name,
    [string]$Project,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve.ps1')
. (Join-Path $PSScriptRoot '..' 'lib' 'resolve-additions.ps1')
. (Join-Path $PSScriptRoot '..' 'lib' 'agents-plugin.ps1')

$sessionRoot = Join-Path $env:USERPROFILE '.copilot\session-state'
if (-not (Test-Path $sessionRoot)) { New-Item -ItemType Directory -Path $sessionRoot -Force | Out-Null }
$atCtx = Find-AtCtxDir
if (-not (Test-Path $atCtx)) { New-Item -ItemType Directory -Path $atCtx -Force | Out-Null }

function Show-HelpText {
    Write-Host 'ctx session - named persistent sessions'
    Write-Host ''
    Write-Host '  ctx session list'
    Write-Host '  ctx session create <name> --project <id>'
    Write-Host '  ctx session resume <name>'
    Write-Host ''
    Write-Host 'The home edition prepares named session folders and wedge agents.'
    Write-Host 'If an external CLI is available, resume prints the exact launch command.'
}

function New-HomeSession {
    param([string]$SessionName, [string]$ProjectId)
    if (-not $ProjectId) { throw 'Specify --project <id> or use ctx --project <id> session create <name>.' }
    $resolved = Resolve-CtxProjectByName $ProjectId
    if (-not $resolved) { throw "Unknown project: $ProjectId" }
    $sessionDir = Join-Path $sessionRoot $SessionName
    if (-not (Test-Path $sessionDir)) { New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null }
    $filesDir = Join-Path $sessionDir 'files'
    if (-not (Test-Path $filesDir)) { New-Item -ItemType Directory -Path $filesDir -Force | Out-Null }
    $agentName = Get-WedgeAgentName -ProjectId $resolved.ProjectId
    $agentFile = Build-WedgeAgentFile -FrameworkDir (Split-Path -Parent $PSScriptRoot) -AtCtxDir $atCtx -AgentName $agentName -ProjectId $resolved.ProjectId -Role 'project'
    $workspace = [ordered]@{
        session_name = $SessionName
        project = $resolved.ProjectId
        context_dir = $resolved.ContextDir
        agent = "ctx:$agentName"
        created = (Get-Date -Format 'o')
    }
    $workspace | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $sessionDir 'workspace.json') -Encoding UTF8
    Write-Host 'SESSION CREATED' -ForegroundColor Green
    Write-Host "  Name:      $SessionName"
    Write-Host "  Project:   $($resolved.ProjectId)"
    Write-Host "  Agent:     ctx:$agentName"
    Write-Host "  AgentFile: $agentFile" -ForegroundColor DarkGray
}

function Show-Sessions {
    Write-Host 'NAMED SESSIONS' -ForegroundColor Cyan
    Write-Host ''
    $items = @(Get-ChildItem $sessionRoot -Directory -ErrorAction SilentlyContinue)
    if ($items.Count -eq 0) { Write-Host '  No named sessions yet.' -ForegroundColor DarkGray; return }
    foreach ($item in $items) {
        $ws = Join-Path $item.FullName 'workspace.json'
        $project = ''
        if (Test-Path $ws) {
            try { $project = (Get-Content $ws -Raw | ConvertFrom-Json).project } catch {}
        }
        $age = [Math]::Round(((Get-Date) - $item.LastWriteTime).TotalHours)
        $ageText = if ($age -lt 1) { 'now' } elseif ($age -lt 24) { "${age}h" } else { "$([Math]::Round($age / 24))d" }
        Write-Host "  $($item.Name) [$project] $ageText" -ForegroundColor White
    }
}

function Resume-HomeSession {
    param([string]$SessionName)
    $sessionDir = Join-Path $sessionRoot $SessionName
    if (-not (Test-Path $sessionDir)) { throw "Session not found: $SessionName" }
    $workspaceFile = Join-Path $sessionDir 'workspace.json'
    if (-not (Test-Path $workspaceFile)) { throw "Missing workspace metadata for $SessionName" }
    $ws = Get-Content $workspaceFile -Raw | ConvertFrom-Json
    Write-Host 'RESUME SESSION' -ForegroundColor Cyan
    Write-Host "  Name:    $SessionName"
    Write-Host "  Project: $($ws.project)"
    Write-Host "  Agent:   $($ws.agent)"
    Write-Host ''
    $pluginDir = Initialize-AgentsPlugin -AtCtxDir $atCtx
    $agency = Get-Command agency -ErrorAction SilentlyContinue
    if ($agency) {
        Write-Host 'Suggested command:' -ForegroundColor Yellow
        Write-Host "  agency copilot --resume $SessionName --plugin-dir `"$pluginDir`" --agent $($ws.agent)" -ForegroundColor Gray
    } else {
        Write-Host 'No external session runner found in PATH.' -ForegroundColor Yellow
        Write-Host 'Use the session folder and agent file with your preferred CLI or editor.' -ForegroundColor Gray
        Write-Host "  SessionDir: $sessionDir" -ForegroundColor Gray
        Write-Host "  PluginDir:  $pluginDir" -ForegroundColor Gray
    }
}

if ($Help) { Show-HelpText; exit 0 }

switch ($Action.ToLower()) {
    'help' { Show-HelpText }
    'list' { Show-Sessions }
    'create' {
        if (-not $Name) { throw 'Usage: ctx session create <name> --project <id>' }
        $projectId = if ($Project) { $Project } elseif ($env:CTX_PROJECT_ID) { $env:CTX_PROJECT_ID } else { $null }
        New-HomeSession -SessionName $Name -ProjectId $projectId
    }
    'resume' {
        if (-not $Name) { throw 'Usage: ctx session resume <name>' }
        Resume-HomeSession -SessionName $Name
    }
    default { throw 'Use: list, create, resume' }
}
