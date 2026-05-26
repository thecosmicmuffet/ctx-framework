. (Join-Path $PSScriptRoot 'resolve.ps1')
$_extra = Join-Path $PSScriptRoot 'resolve-additions.ps1'
if (Test-Path $_extra) { . $_extra }

function Get-CtxConfig {
    param([string]$ProjectName)
    $resolved = if ($ProjectName) { Resolve-CtxProjectByName $ProjectName } else { Resolve-CtxProject }
    if (-not $resolved.ProjectId) {
        Write-Error "No project context found. Run 'ctx register' inside a project first."
        exit 1
    }
    Set-CtxEnvironment $resolved
    return [PSCustomObject]@{
        current_project = $resolved.ProjectId
        projects = [PSCustomObject]@{
            $resolved.ProjectId = [PSCustomObject]@{
                git_root = $resolved.CanonicalRoot
                project_root = if ($resolved.CanonicalRoot) { $resolved.CanonicalRoot } else { $resolved.ContextDir }
                context_dir = $resolved.ContextDir
                type = $resolved.Type
            }
        }
    }
}

function Get-CtxContextPath {
    param([string]$ProjectName)
    $config = Get-CtxConfig -ProjectName $ProjectName
    $projectName_ = $config.current_project
    $ctx = $config.projects.$projectName_.context_dir
    if (-not (Test-Path $ctx)) {
        New-Item -ItemType Directory -Path $ctx -Force | Out-Null
    }
    return $ctx
}
