function Get-AtCtxTrainingDir {
    $atCtx = Find-AtCtxDir
    $trainingDir = Join-Path $atCtx 'training'
    if (-not (Test-Path $trainingDir)) {
        New-Item -ItemType Directory -Path $trainingDir -Force | Out-Null
    }
    return $trainingDir
}

function Get-QuickBytesHash {
    param([string]$FilePath)
    if (-not $FilePath -or -not (Test-Path $FilePath)) { return '000000000000' }
    try {
        return (Get-FileHash $FilePath -Algorithm SHA256).Hash.Substring(0, 12).ToLower()
    } catch {
        return '000000000000'
    }
}

function Emit-ImplicitLabel {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$FilePath,
        [string]$Project = 'home',
        [string]$Token = '?',
        [string]$Scope = 'Mind',
        [string]$Trust = 'FRESH',
        [int]$AgeDays = 0,
        [double]$Salience = 0.5,
        [string]$Affordance = 'read',
        [string]$Opponent,
        [Parameter(Mandatory)][string]$Source,
        [string]$Note
    )
    try {
        $labelsFile = Join-Path (Get-AtCtxTrainingDir) 'labels.jsonl'
        $entry = [ordered]@{
            path = $Path
            project = $Project
            bytes_hash = (Get-QuickBytesHash $FilePath)
            token = $Token
            scope = $Scope
            trust = $Trust
            age_days = $AgeDays
            confidence = 0.6
            labeled_by = 'implicit'
            timestamp = (Get-Date -Format 'o')
            salience = [Math]::Round($Salience, 2)
            affordance = $Affordance
            source = $Source
        }
        if ($Opponent) { $entry['opponent'] = $Opponent }
        if ($Note) { $entry['note'] = $Note }
        Add-Content $labelsFile (($entry | ConvertTo-Json -Compress))
    } catch {}
}

function Get-ArtifactAge {
    param([string]$FilePath)
    if (-not $FilePath -or -not (Test-Path $FilePath)) { return 0 }
    return [Math]::Max(0, [int]((Get-Date) - (Get-Item $FilePath).LastWriteTime).TotalDays)
}

function Get-TrustFromAge {
    param([int]$AgeDays)
    if ($AgeDays -le 3) { return 'FRESH' }
    if ($AgeDays -le 14) { return 'AGING' }
    return 'STALE'
}
