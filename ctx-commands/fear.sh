#!/usr/bin/env bash
# Fear Kit - Context rotation and regrounding for agents and humans
# Usage: ./ctx fear [invoke|rotate|reground|assess|queue]

set -e

# Color codes
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;36m'
COLOR_GRAY='\033[0;90m'
COLOR_BOLD='\033[1m'

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FEAR_DIR="$SCRIPT_DIR/.context-data/fear"
QUEUE_FILE="$FEAR_DIR/queue.json"
ORCHESTRATION_FILE="$FEAR_DIR/orchestration.json"
LITURGIES_FILE="$FEAR_DIR/liturgies.json"
SNAPSHOTS_DIR="$FEAR_DIR/snapshots"
HANDOFFS_DIR="$FEAR_DIR/handoffs"

# Command and arguments
COMMAND="${1:-assess}"
TARGET="${2:-}"

# Help flag
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    COMMAND="help"
fi

# Function to show help
show_help() {
    cat <<EOF
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

EOF
}

# Function to get timestamp
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Function to check if jq is available
has_jq() {
    command -v jq >/dev/null 2>&1
}

# Function to initialize fear directory structure
init_fear_dir() {
    if [[ ! -d "$FEAR_DIR" ]]; then
        mkdir -p "$FEAR_DIR"
        mkdir -p "$SNAPSHOTS_DIR"
        mkdir -p "$HANDOFFS_DIR"
    fi

    if [[ ! -f "$QUEUE_FILE" ]]; then
        if has_jq; then
            echo '{"active":[],"rotation_history":[]}' | jq '.' > "$QUEUE_FILE"
        else
            cat > "$QUEUE_FILE" <<EOF
{
  "active": [],
  "rotation_history": []
}
EOF
        fi
    fi
}

# Function to invoke fear
invoke_fear() {
    local project_id="$1"

    if [[ -z "$project_id" ]]; then
        echo -e "${COLOR_RED}ERROR: Project ID required for invocation${COLOR_RESET}"
        echo "Usage: ./ctx fear invoke <project-id>"
        return 1
    fi

    init_fear_dir

    echo -e "${COLOR_BLUE}🦉 Invoking fear for: $project_id${COLOR_RESET}"
    echo ""

    # Create snapshot
    local timestamp=$(date +"%Y-%m-%d-%H%M%S")
    local snapshot_file="$SNAPSHOTS_DIR/$project_id-$timestamp.json"

    echo "Creating snapshot at: $snapshot_file"
    echo ""
    echo -e "${COLOR_BOLD}VESSEL ANALYSIS - Which has knotted?${COLOR_RESET}"
    echo "  1. Cargo (content/what we're building)"
    echo "  2. Container (structure/how we're building)"
    echo "  3. Journey (process/the path itself)"
    echo ""

    # Create snapshot JSON
    if has_jq; then
        jq -n \
            --arg project_id "$project_id" \
            --arg timestamp "$(get_timestamp)" \
            '{
                meta: {
                    project_id: $project_id,
                    timestamp: $timestamp,
                    invoked_by: "agent"
                },
                state: {
                    assumptions: [],
                    what_seemed_true: "",
                    impediment_description: "",
                    vessel_analysis: {
                        cargo_status: "unknown",
                        container_status: "unknown",
                        journey_status: "unknown",
                        knot_location: "unknown"
                    }
                },
                context: {
                    recent_iterations: [],
                    confidence_level: "unknown",
                    spiral_indicators: []
                },
                rotation: {
                    perspectives_tried: [],
                    suggested_pivots: [],
                    reground_triggers: []
                }
            }' > "$snapshot_file"
    else
        cat > "$snapshot_file" <<EOF
{
  "meta": {
    "project_id": "$project_id",
    "timestamp": "$(get_timestamp)",
    "invoked_by": "agent"
  },
  "state": {
    "assumptions": [],
    "what_seemed_true": "",
    "impediment_description": "",
    "vessel_analysis": {
      "cargo_status": "unknown",
      "container_status": "unknown",
      "journey_status": "unknown",
      "knot_location": "unknown"
    }
  },
  "context": {
    "recent_iterations": [],
    "confidence_level": "unknown",
    "spiral_indicators": []
  },
  "rotation": {
    "perspectives_tried": [],
    "suggested_pivots": [],
    "reground_triggers": []
  }
}
EOF
    fi

    # Update queue - add project if not exists
    if has_jq; then
        local queue_content=$(cat "$QUEUE_FILE")
        local project_exists=$(echo "$queue_content" | jq --arg id "$project_id" '.active[] | select(.id == $id) | .id' -r)

        if [[ -z "$project_exists" ]]; then
            echo "Project not in queue. Adding..."
            echo "$queue_content" | jq \
                --arg id "$project_id" \
                --arg path "$TARGET" \
                --arg timestamp "$(get_timestamp)" \
                '.active += [{
                    id: $id,
                    path: $path,
                    priority: 1,
                    frequency: "medium",
                    added: $timestamp,
                    last_rotation: null,
                    rotation_count: 0,
                    notes: ""
                }]' > "$QUEUE_FILE"
        fi
    fi

    echo -e "${COLOR_GREEN}Fear invoked. Snapshot created.${COLOR_RESET}"
    echo "Next: Analyze vessel, then rotate or reground."
}

# Function to rotate context
invoke_rotate() {
    local to_project="$1"

    if [[ -z "$to_project" ]]; then
        echo -e "${COLOR_RED}ERROR: Target project required for rotation${COLOR_RESET}"
        echo "Usage: ./ctx fear rotate <to-project>"
        return 1
    fi

    init_fear_dir

    echo -e "${COLOR_BLUE}🦉 Rotating context to: $to_project${COLOR_RESET}"
    echo ""
    echo "Approaching from the other side..."
    echo ""

    # Create handoff narrative
    local timestamp=$(date +"%Y-%m-%d-%H%M%S")
    local handoff_file="$HANDOFFS_DIR/rotation-$timestamp.md"

    echo "Creating context handoff at: $handoff_file"
    echo ""
    echo -e "${COLOR_GRAY}Agent should compose bridge narrative preserving thread...${COLOR_RESET}"

    # Create handoff file
    cat > "$handoff_file" <<EOF
# Context Rotation Handoff

**Timestamp**: $(get_timestamp)
**From**: current-context
**To**: $to_project
**Reason**: fear-invoked

## Context Bridge

[Agent should fill in narrative that preserves thread]

## Carry Forward

- What remains relevant
- Key insights to preserve
- Open questions

## Fresh Perspective Needed

- What assumptions to challenge
- Which angles to try
- New ground to explore

EOF

    # Update queue rotation history
    if has_jq; then
        local queue_content=$(cat "$QUEUE_FILE")
        echo "$queue_content" | jq \
            --arg timestamp "$(get_timestamp)" \
            --arg to "$to_project" \
            --arg handoff "$handoff_file" \
            '.rotation_history += [{
                timestamp: $timestamp,
                from: "current-context",
                to: $to,
                reason: "fear-invoked",
                handoff_file: $handoff
            }]' > "$QUEUE_FILE"
    fi

    echo -e "${COLOR_GREEN}Rotation initiated. See handoff for context bridge.${COLOR_RESET}"
}

# Function to reground in project
invoke_reground() {
    local project_id="$1"

    if [[ -z "$project_id" ]]; then
        echo -e "${COLOR_RED}ERROR: Project ID required for regrounding${COLOR_RESET}"
        echo "Usage: ./ctx fear reground <project-id>"
        return 1
    fi

    echo -e "${COLOR_BLUE}🦉 Regrounding in: $project_id${COLOR_RESET}"
    echo ""
    echo "Returning with new perspective..."
    echo ""

    # Find latest snapshot
    if [[ -d "$SNAPSHOTS_DIR" ]]; then
        local latest_snapshot=$(find "$SNAPSHOTS_DIR" -name "$project_id-*.json" -type f | sort -r | head -n 1)

        if [[ -n "$latest_snapshot" ]]; then
            local snapshot_name=$(basename "$latest_snapshot")
            echo "Latest snapshot: $snapshot_name"

            if has_jq; then
                local impediment=$(jq -r '.state.impediment_description // "unknown"' "$latest_snapshot")
                local knot=$(jq -r '.state.vessel_analysis.knot_location // "unknown"' "$latest_snapshot")

                echo ""
                echo -e "${COLOR_BOLD}PREVIOUS STATE:${COLOR_RESET}"
                echo "  Impediment: $impediment"
                echo "  Knot: $knot"
            else
                echo ""
                echo -e "${COLOR_BOLD}PREVIOUS STATE:${COLOR_RESET}"
                echo -e "${COLOR_GRAY}  (jq not available - view $latest_snapshot for details)${COLOR_RESET}"
            fi

            echo ""
            echo "Ready to approach from opposed position."
        else
            echo "No snapshots found for $project_id"
        fi
    else
        echo "No snapshots directory found"
    fi
}

# Function to assess queue
invoke_assess() {
    echo -e "${COLOR_BLUE}🦉 FEAR QUEUE ASSESSMENT${COLOR_RESET}"
    echo ""

    if [[ ! -f "$QUEUE_FILE" ]]; then
        echo "No fear queue exists yet."
        return
    fi

    echo "Active Projects in Rotation:"
    echo ""

    if has_jq; then
        local active_count=$(jq '.active | length' "$QUEUE_FILE")

        if [[ "$active_count" -gt 0 ]]; then
            jq -r '.active[] | "  [\(.id)]\n    Path: \(.path)\n    Priority: \(.priority)\n    Frequency: \(.frequency)\n    Rotations: \(.rotation_count)\n    Notes: \(.notes)\n"' "$QUEUE_FILE"
        else
            echo -e "${COLOR_GRAY}  No active projects in queue${COLOR_RESET}"
            echo ""
        fi

        local rotation_count=$(jq '.rotation_history | length' "$QUEUE_FILE")
        echo "Total rotations: $rotation_count"
        echo ""

        if [[ "$rotation_count" -gt 0 ]]; then
            echo "Recent rotations:"
            jq -r '.rotation_history | .[-5:] | .[] | "  \(.timestamp): \(.from) → \(.to)"' "$QUEUE_FILE"
        fi
    else
        echo -e "${COLOR_YELLOW}(jq not available - showing raw queue file)${COLOR_RESET}"
        echo ""
        cat "$QUEUE_FILE"
    fi
}

# Function to show queue
show_queue() {
    if [[ ! -f "$QUEUE_FILE" ]]; then
        echo "No fear queue exists yet."
        return
    fi

    echo "FEAR QUEUE"
    echo "=========="
    echo ""

    if has_jq; then
        # Sort by priority descending
        jq -r '.active | sort_by(.priority) | reverse | .[] |
            (if .frequency == "high" then "⚡"
             elif .frequency == "medium" then "○"
             else "·" end) + " [\(.id)]\n    \(.notes)\n"' "$QUEUE_FILE"
    else
        echo -e "${COLOR_YELLOW}(jq not available - showing raw queue file)${COLOR_RESET}"
        echo ""
        cat "$QUEUE_FILE"
    fi
}

# Function to show liturgy
show_liturgy() {
    local liturgy_id="$1"

    if [[ ! -f "$LITURGIES_FILE" ]]; then
        echo -e "${COLOR_YELLOW}No liturgies file found at: $LITURGIES_FILE${COLOR_RESET}"
        echo "Create $LITURGIES_FILE to define liturgies"
        return
    fi

    if [[ -n "$liturgy_id" ]]; then
        # Show specific liturgy
        if has_jq; then
            local liturgy_exists=$(jq --arg id "$liturgy_id" '.liturgies[] | select(.id == $id)' "$LITURGIES_FILE")

            if [[ -n "$liturgy_exists" ]]; then
                local text=$(echo "$liturgy_exists" | jq -r '.text')
                local context=$(echo "$liturgy_exists" | jq -r '.context')
                local application=$(echo "$liturgy_exists" | jq -r '.application')

                echo ""
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo "$text"
                echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                echo ""
                echo "Context: $context"
                echo "Application: $application"
                echo ""
            else
                echo "Liturgy '$liturgy_id' not found"
            fi
        else
            echo -e "${COLOR_YELLOW}(jq not available - showing all liturgies)${COLOR_RESET}"
            cat "$LITURGIES_FILE"
        fi
    else
        # Show all liturgies
        echo "Available Liturgies:"
        echo ""

        if has_jq; then
            jq -r '.liturgies[] | "  \(.id)\n    \(.text)\n"' "$LITURGIES_FILE"
        else
            cat "$LITURGIES_FILE"
        fi
    fi
}

# Main execution
case "${COMMAND,,}" in
    invoke)
        invoke_fear "$TARGET"
        ;;
    rotate)
        invoke_rotate "$TARGET"
        ;;
    reground)
        invoke_reground "$TARGET"
        ;;
    assess)
        invoke_assess
        ;;
    queue)
        show_queue
        ;;
    liturgy)
        show_liturgy "$TARGET"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac
