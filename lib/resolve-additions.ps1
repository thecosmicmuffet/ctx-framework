function Resolve-CtxProjectByName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Name)

    $atCtxDir = Find-AtCtxDir
    $registry = Get-AtCtxRegistry
    if (-not $registry -or -not $registry.projects) { return $null }

    foreach ($prop in $registry.projects.PSObject.Properties) {
        $proj = $prop.Value
        if ($prop.Name -eq $Name -or $prop.Name -ieq $Name -or ($proj.name -and $proj.name -ieq $Name) -or ($proj.keywords -and $Name -in $proj.keywords)) {
            return [PSCustomObject]@{
                ProjectId = $prop.Name
                ProjectName = if ($proj.name) { $proj.name } else { $prop.Name }
                ContextDir = Join-Path $atCtxDir 'projects' $prop.Name
                Method = 'name'
                AtCtxDir = $atCtxDir
                Deprecated = $false
                CanonicalRoot = if ($proj.paths -and $proj.paths.Count -gt 0) { $proj.paths[0] } else { $null }
                Type = if ($proj.type) { $proj.type } else { 'project' }
            }
        }
    }
    return $null
}
