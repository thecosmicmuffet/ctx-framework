#!/usr/bin/env pwsh
# Fear Kit - Context rotation and regrounding for agents and humans
# Usage: ./ctx fear [invoke|rotate|reground|assess|queue]

param(
    [Parameter(Position=0)]
    [string]$Command = "assess",

    [Parameter(Position=1)]
    [string]$Target = "",

    [switch]$Help
)

$FEAR_DIR = ".context/fear"
$QUEUE_FILE = "$FEAR_DIR/queue.json"
$ORCHESTRATION_FILE = "$FEAR_DIR/orchestration.json"
$LITURGIES_FILE = "$FEAR_DIR/liturgies.json"
$SNAPSHOTS_DIR = "$FEAR_DIR/snapshots"
$HANDOFFS_DIR = "$FEAR_DIR/handoffs"

function Show-Help {
    Write-Host @"
Fear Kit - Context Rotation and Regrounding

USAGE:
    ./ctx fear [command] [options]

COMMANDS:
    invoke [project]     - Snapshot current state, analyze impediment
    rotate [to-project]  - Pivot to different project with context handoff
    reground [project]   - Return to project with new perspective
    assess               - Evaluate queue health, detect spirals
    queue                - Show current rotation queue
    liturgy [id]         - Display liturgy for impasse moment

PHILOSOPHY:
    Fear signals loss of contact at the mold/form boundary. When iteration
    becomes circular or assumptions destabilize, invoke fear to rotate
    perspective and find traction.

    The vessel premise: something carried, something carrying, something
    traversed. Ask which of the three has knotted.

EXAMPLES:
    ./ctx fear invoke high-sin-prototype
    ./ctx fear rotate shader-experiments
    ./ctx fear liturgy submission
    ./ctx fear queue

INTEGRATION:
    Agents may invoke fear autonomously when:
    - Iteration spirals without progress
    - Superlative agreement masks divergence
    - Task identity becomes unstable
    - Unproductive avenues confine exploration

"@
}

function Get-Timestamp {
    return Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
}

function Invoke-Fear {
    param([string]$ProjectId)

    if (-not $ProjectId) {
        Write-Host "ERROR: Project ID required for invocation"
        Write-Host "Usage: ./ctx fear invoke <project-id>"
        return
    }

    Write-Host "🦉 Invoking fear for: $ProjectId"
    Write-Host ""

    # Load queue
    $queue = Get-Content $QUEUE_FILE | ConvertFrom-Json

    # Find project in queue
    $project = $queue.active | Where-Object { $_.id -eq $ProjectId }

    if (-not $project) {
        Write-Host "Project not in queue. Adding..."
        $project = @{
            id = $ProjectId
            path = $Target
            priority = 1
            frequency = "medium"
            added = Get-Timestamp
            last_rotation = $null
            rotation_count = 0
            notes = ""
        }
        $queue.active += $project
    }

    # Create snapshot
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $snapshotFile = "$SNAPSHOTS_DIR/$ProjectId-$timestamp.json"

    Write-Host "Creating snapshot at: $snapshotFile"
    Write-Host ""
    Write-Host "VESSEL ANALYSIS - Which has knotted?"
    Write-Host "  1. Cargo (content/what we're building)"
    Write-Host "  2. Container (structure/how we're building)"
    Write-Host "  3. Journey (process/the path itself)"
    Write-Host ""

    # Agent should fill this in when invoking
    $snapshot = @{
        meta = @{
            project_id = $ProjectId
            timestamp = Get-Timestamp
            invoked_by = "agent"
        }
        state = @{
            assumptions = @()
            what_seemed_true = ""
            impediment_description = ""
            vessel_analysis = @{
                cargo_status = "unknown"
                container_status = "unknown"
                journey_status = "unknown"
                knot_location = "unknown"
            }
        }
        context = @{
            recent_iterations = @()
            confidence_level = "unknown"
            spiral_indicators = @()
        }
        rotation = @{
            perspectives_tried = @()
            suggested_pivots = @()
            reground_triggers = @()
        }
    }

    $snapshot | ConvertTo-Json -Depth 10 | Out-File $snapshotFile -Encoding UTF8

    # Update queue
    $queue | ConvertTo-Json -Depth 10 | Out-File $QUEUE_FILE -Encoding UTF8

    Write-Host "Fear invoked. Snapshot created."
    Write-Host "Next: Analyze vessel, then rotate or reground."
}

function Invoke-Rotate {
    param([string]$ToProject)

    Write-Host "🦉 Rotating context to: $ToProject"
    Write-Host ""
    Write-Host "Approaching from the other side..."
    Write-Host ""

    # Load queue and update rotation
    $queue = Get-Content $QUEUE_FILE | ConvertFrom-Json

    # Create handoff narrative
    $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
    $handoffFile = "$HANDOFFS_DIR/rotation-$timestamp.md"

    Write-Host "Creating context handoff at: $handoffFile"
    Write-Host ""
    Write-Host "Agent should compose bridge narrative preserving thread..."

    # Record rotation in history
    $rotation = @{
        timestamp = Get-Timestamp
        from = "current-context"
        to = $ToProject
        reason = "fear-invoked"
        handoff_file = $handoffFile
    }

    $queue.rotation_history += $rotation
    $queue | ConvertTo-Json -Depth 10 | Out-File $QUEUE_FILE -Encoding UTF8

    Write-Host "Rotation initiated. See handoff for context bridge."
}

function Invoke-Reground {
    param([string]$ProjectId)

    Write-Host "🦉 Regrounding in: $ProjectId"
    Write-Host ""
    Write-Host "Returning with new perspective..."
    Write-Host ""

    # Load latest snapshot
    $snapshots = Get-ChildItem $SNAPSHOTS_DIR -Filter "$ProjectId-*.json" | Sort-Object Name -Descending

    if ($snapshots.Count -gt 0) {
        $latest = $snapshots[0]
        Write-Host "Latest snapshot: $($latest.Name)"
        $snapshot = Get-Content $latest.FullName | ConvertFrom-Json

        Write-Host ""
        Write-Host "PREVIOUS STATE:"
        Write-Host "  Impediment: $($snapshot.state.impediment_description)"
        Write-Host "  Knot: $($snapshot.state.vessel_analysis.knot_location)"
        Write-Host ""
        Write-Host "Ready to approach from opposed position."
    } else {
        Write-Host "No snapshots found for $ProjectId"
    }
}

function Invoke-Assess {
    Write-Host "🦉 FEAR QUEUE ASSESSMENT"
    Write-Host ""

    if (-not (Test-Path $QUEUE_FILE)) {
        Write-Host "No fear queue exists yet."
        return
    }

    $queue = Get-Content $QUEUE_FILE | ConvertFrom-Json

    Write-Host "Active Projects in Rotation:"
    Write-Host ""

    foreach ($project in $queue.active) {
        Write-Host "  [$($project.id)]"
        Write-Host "    Path: $($project.path)"
        Write-Host "    Priority: $($project.priority)"
        Write-Host "    Frequency: $($project.frequency)"
        Write-Host "    Rotations: $($project.rotation_count)"
        Write-Host "    Notes: $($project.notes)"
        Write-Host ""
    }

    Write-Host "Total rotations: $($queue.rotation_history.Count)"
    Write-Host ""
    Write-Host "Recent rotations:"
    $recent = $queue.rotation_history | Select-Object -Last 5
    foreach ($r in $recent) {
        Write-Host "  $($r.timestamp): $($r.from) → $($r.to)"
    }
}

function Show-Queue {
    if (-not (Test-Path $QUEUE_FILE)) {
        Write-Host "No fear queue exists yet."
        return
    }

    $queue = Get-Content $QUEUE_FILE | ConvertFrom-Json

    Write-Host "FEAR QUEUE"
    Write-Host "=========="
    Write-Host ""

    # Sort by priority and frequency
    $sorted = $queue.active | Sort-Object -Property priority -Descending

    foreach ($project in $sorted) {
        $indicator = switch ($project.frequency) {
            "high" { "⚡" }
            "medium" { "○" }
            "low" { "·" }
            default { "·" }
        }

        Write-Host "$indicator [$($project.id)]"
        Write-Host "    $($project.notes)"
        Write-Host ""
    }
}

function Show-Liturgy {
    param([string]$LiturgyId)

    $liturgies = Get-Content $LITURGIES_FILE | ConvertFrom-Json

    if ($LiturgyId) {
        $liturgy = $liturgies.liturgies | Where-Object { $_.id -eq $LiturgyId }
        if ($liturgy) {
            Write-Host ""
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            Write-Host $liturgy.text
            Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            Write-Host ""
            Write-Host "Context: $($liturgy.context)"
            Write-Host "Application: $($liturgy.application)"
            Write-Host ""
        } else {
            Write-Host "Liturgy '$LiturgyId' not found"
        }
    } else {
        Write-Host "Available Liturgies:"
        Write-Host ""
        foreach ($l in $liturgies.liturgies) {
            Write-Host "  $($l.id)"
            Write-Host "    $($l.text)"
            Write-Host ""
        }
    }
}

# Main execution
if ($Help) {
    Show-Help
    exit 0
}

switch ($Command.ToLower()) {
    "invoke" { Invoke-Fear -ProjectId $Target }
    "rotate" { Invoke-Rotate -ToProject $Target }
    "reground" { Invoke-Reground -ProjectId $Target }
    "assess" { Invoke-Assess }
    "queue" { Show-Queue }
    "liturgy" { Show-Liturgy -LiturgyId $Target }
    default { Show-Help }
}
