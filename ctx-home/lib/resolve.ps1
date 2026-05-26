function Find-AtCtxDir {
    if ($env:CTX_ATCTX_DIR) { return $env:CTX_ATCTX_DIR }
    $ctxHome = if ($env:CTX_HOME) { $env:CTX_HOME } else { Split-Path -Parent $PSScriptRoot }
    return (Join-Path $ctxHome '@ctx')
}

function Get-AtCtxRegistry {
    $atCtxDir = Find-AtCtxDir
    $registryFile = Join-Path $atCtxDir 'registry.json'
    if (-not (Test-Path $registryFile)) { return $null }
    try { return Get-Content $registryFile -Raw | ConvertFrom-Json } catch { return $null }
}

function Resolve-CtxProject {
    [CmdletBinding()]
    param([string]$FromPath = (Get-Location).Path)

    $result = [PSCustomObject]@{
        ProjectId = $null
        ProjectName = $null
        ContextDir = $null
        Method = $null
        AtCtxDir = Find-AtCtxDir
        Deprecated = $false
        CanonicalRoot = $null
        Type = 'project'
    }

    if ($env:CTX_PROJECT_ID -and $env:CTX_CONTEXT_DIR) {
        $result.ProjectId = $env:CTX_PROJECT_ID
        $result.ProjectName = if ($env:CTX_PROJECT_NAME) { $env:CTX_PROJECT_NAME } else { $env:CTX_PROJECT_ID }
        $result.ContextDir = $env:CTX_CONTEXT_DIR
        $result.Method = if ($env:CTX_RESOLVE_METHOD) { $env:CTX_RESOLVE_METHOD } else { 'env' }
        $result.CanonicalRoot = $env:CTX_PROJECT_ROOT
        if ($env:CTX_PROJECT_TYPE) { $result.Type = $env:CTX_PROJECT_TYPE }
        return $result
    }

    $registry = Get-AtCtxRegistry
    if ($registry -and $registry.projects) {
        $best = $null
        $bestLen = -1
        foreach ($prop in $registry.projects.PSObject.Properties) {
            $proj = $prop.Value
            foreach ($p in @($proj.paths)) {
                if (-not $p) { continue }
                $norm = $p.TrimEnd('\\', '/')
                if ($FromPath.StartsWith($norm, [System.StringComparison]::OrdinalIgnoreCase) -and $norm.Length -gt $bestLen) {
                    $best = $prop
                    $bestLen = $norm.Length
                }
            }
        }
        if ($best) {
            $proj = $best.Value
            $result.ProjectId = $best.Name
            $result.ProjectName = if ($proj.name) { $proj.name } else { $best.Name }
            $result.ContextDir = Join-Path $result.AtCtxDir 'projects' $best.Name
            $result.Method = 'path'
            $result.CanonicalRoot = if ($proj.paths -and $proj.paths.Count -gt 0) { $proj.paths[0] } else { $null }
            if ($proj.type) { $result.Type = $proj.type }
            return $result
        }

        try {
            $remoteLines = git remote -v 2>$null
            $remote = $remoteLines | Where-Object { $_ -match '\(fetch\)' } | Select-Object -First 1
            if ($remote -match '^\S+\s+(\S+)\s+\(fetch\)') {
                $remoteUrl = $matches[1]
                foreach ($prop in $registry.projects.PSObject.Properties) {
                    $proj = $prop.Value
                    if ($proj.remotes -and $proj.remotes -contains $remoteUrl) {
                        $result.ProjectId = $prop.Name
                        $result.ProjectName = if ($proj.name) { $proj.name } else { $prop.Name }
                        $result.ContextDir = Join-Path $result.AtCtxDir 'projects' $prop.Name
                        $result.Method = 'remote'
                        $result.CanonicalRoot = if ($proj.paths -and $proj.paths.Count -gt 0) { $proj.paths[0] } else { $null }
                        if ($proj.type) { $result.Type = $proj.type }
                        return $result
                    }
                }
            }
        } catch {}
    }

    return $result
}

function Set-CtxEnvironment {
    param([pscustomobject]$Resolution)
    if (-not $Resolution.ProjectId) { return }
    $env:CTX_PROJECT_ID = $Resolution.ProjectId
    $env:CTX_PROJECT_NAME = if ($Resolution.ProjectName) { $Resolution.ProjectName } else { $Resolution.ProjectId }
    $env:CTX_CONTEXT_DIR = $Resolution.ContextDir
    $env:CTX_ATCTX_DIR = $Resolution.AtCtxDir
    $env:CTX_RESOLVE_METHOD = $Resolution.Method
    if ($Resolution.CanonicalRoot) { $env:CTX_PROJECT_ROOT = $Resolution.CanonicalRoot }
    if ($Resolution.Type) { $env:CTX_PROJECT_TYPE = $Resolution.Type }
}
