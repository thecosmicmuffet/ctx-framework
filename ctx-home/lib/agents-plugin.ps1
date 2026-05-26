function Get-WedgeAgentName {
    param([Parameter(Mandatory)][string]$ProjectId)
    return ($ProjectId -replace '^ctx-', '')
}

function Get-AgentsPluginDir {
    param([Parameter(Mandatory)][string]$AtCtxDir)
    return (Join-Path $AtCtxDir 'agents-plugin')
}

function Initialize-AgentsPlugin {
    param([Parameter(Mandatory)][string]$AtCtxDir)
    $pluginDir = Get-AgentsPluginDir -AtCtxDir $AtCtxDir
    $agentsDir = Join-Path $pluginDir 'agents'
    if (-not (Test-Path $agentsDir)) { New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null }
    $manifest = Join-Path $pluginDir 'plugin.json'
    if (-not (Test-Path $manifest)) {
        $data = [ordered]@{
            name = 'ctx'
            description = 'ctx home wedge agents'
            version = '0.1.0'
            author = [ordered]@{ name = 'ctx home' }
            keywords = @('ctx', 'context', 'wedge')
            agents = 'agents/'
        }
        $data | ConvertTo-Json -Depth 5 | Set-Content $manifest -Encoding UTF8
    }
    return $pluginDir
}

function Build-WedgeAgentFile {
    param(
        [Parameter(Mandatory)][string]$FrameworkDir,
        [Parameter(Mandatory)][string]$AtCtxDir,
        [Parameter(Mandatory)][string]$AgentName,
        [Parameter(Mandatory)][string]$ProjectId,
        [string]$Role = 'project'
    )
    $pluginDir = Initialize-AgentsPlugin -AtCtxDir $AtCtxDir
    $agentFile = Join-Path $pluginDir 'agents' "$AgentName.agent.md"
    if (Test-Path $agentFile) { return $agentFile }

    $body = @"
---
name: $AgentName
description: ctx $Role wedge for $ProjectId
tools: ['*']
user-invocable: true
---

# ctx $AgentName wedge

You are the $Role incarnation for `$ProjectId`.

First actions:
1. `ctx chart --project $ProjectId`
2. `ctx scent read`
3. `ctx state --project $ProjectId`
4. begin work

Keep orientation compact.
Use `ctx dock` before context gets crowded.
"@
    Set-Content $agentFile -Value $body -Encoding UTF8
    return $agentFile
}
