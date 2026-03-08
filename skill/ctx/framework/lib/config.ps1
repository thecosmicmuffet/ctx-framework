# config.ps1 - Shared configuration loading for ctx commands
# Search upward from PWD to find .ctxconfig (same logic as ctx.ps1)

function Find-CtxConfig {
    $SearchDir = Get-Location
    while ($SearchDir) {
        $TestPath = Join-Path $SearchDir ".ctxconfig"
        if (Test-Path $TestPath) {
            return $TestPath
        }
        $Parent = Split-Path -Parent $SearchDir
        if ($Parent -eq $SearchDir) { break }
        $SearchDir = $Parent
    }
    return $null
}

function Get-CtxConfig {
    $configPath = Find-CtxConfig
    if (-not $configPath) {
        Write-Error ".ctxconfig not found. Run bootstrap.ps1 first or navigate to a ctx-enabled project."
        exit 1
    }
    return Get-Content $configPath -Raw | ConvertFrom-Json
}

function Get-CtxContextPath {
    $config = Get-CtxConfig
    $projectName = $config.current_project
    $projectConfig = $config.projects.$projectName
    $gitRoot = $projectConfig.git_root
    $projectRoot = $projectConfig.project_root -replace '\[git\]', $gitRoot
    $contextPath = $projectConfig.context_dir -replace '\[git\]', $gitRoot -replace '\[project\]', $projectRoot
    return $contextPath
}
