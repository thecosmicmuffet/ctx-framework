#!/usr/bin/env bash
# ctx core library
# Provides hierarchical context discovery and environment setup

set -euo pipefail

# === Context Discovery ===

find_context_hierarchy() {
    local contexts=()
    local dir="$PWD"
    local stop_at_project="${CTX_STOP_AT_PROJECT:-true}"

    # Search upward, collecting all .ctx directories
    while [[ "$dir" != "/" && "$dir" != "$(dirname "$HOME")" ]]; do
        if [[ -d "$dir/.ctx" ]]; then
            contexts=("$dir/.ctx" "${contexts[@]}")

            # Check for project root indicators
            if [[ "$stop_at_project" == "true" ]]; then
                if [[ -f "$dir/.ctxconfig" ]] ||
                   [[ -f "$dir"/*.sln ]] ||
                   [[ -d "$dir/.git" && -f "$dir/.git/config" ]]; then
                    break
                fi
            fi
        fi
        dir="$(dirname "$dir")"
    done

    # Add user-level context if exists
    if [[ -d "$HOME/.ctx" ]]; then
        contexts=("$HOME/.ctx" "${contexts[@]}")
    fi

    printf "%s\n" "${contexts[@]}"
}

find_project_root() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        # Strong indicators (stop immediately)
        [[ -f "$dir/.ctxconfig" ]] && { echo "$dir"; return; }

        # .sln files (Visual Studio solution)
        if compgen -G "$dir/*.sln" > /dev/null 2>&1; then
            echo "$dir"
            return
        fi

        # Other project files
        [[ -f "$dir/Cargo.toml" ]] && { echo "$dir"; return; }
        [[ -f "$dir/package.json" && -d "$dir/node_modules" ]] && { echo "$dir"; return; }

        # Git repository with multiple projects
        if [[ -d "$dir/.git" ]]; then
            local project_count=0
            project_count=$(find "$dir" -maxdepth 3 \( -name "*.sln" -o -name "Cargo.toml" -o -name "package.json" \) 2>/dev/null | wc -l)
            if [[ $project_count -gt 1 ]]; then
                echo "$dir"
                return
            fi
        fi

        dir="$(dirname "$dir")"
    done

    # Fallback to git root or PWD
    git rev-parse --show-toplevel 2>/dev/null || echo "$PWD"
}

find_nearest_context() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.ctx" ]]; then
            echo "$dir/.ctx"
            return
        fi
        dir="$(dirname "$dir")"
    done

    echo ""
}

find_ctx_home() {
    # 1. Environment variable
    if [[ -n "${CTX_HOME:-}" && -d "$CTX_HOME" ]]; then
        echo "$CTX_HOME"
        return
    fi

    # 2. User installation
    if [[ -d "$HOME/.ctx" ]]; then
        echo "$HOME/.ctx"
        return
    fi

    # 3. Search upward from current directory
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/ctx" && -f "$dir/ctx/lib/core.sh" ]]; then
            echo "$dir/ctx"
            return
        fi
        dir="$(dirname "$dir")"
    done

    # 4. System PATH
    if command -v ctx >/dev/null 2>&1; then
        local ctx_path
        ctx_path=$(command -v ctx)
        dirname "$(dirname "$ctx_path")"
        return
    fi

    echo ""
}

# === Environment Setup ===

setup_environment() {
    # CTX home location
    export CTX_HOME="${CTX_HOME:-$(find_ctx_home)}"

    if [[ -z "$CTX_HOME" ]]; then
        echo "Error: ctx not found" >&2
        echo "Set CTX_HOME or install to ~/.ctx" >&2
        return 1
    fi

    # Project and context roots
    export CTX_PROJECT_ROOT="${CTX_PROJECT_ROOT:-$(find_project_root)}"
    export CTX_CONTEXT_ROOT="${CTX_CONTEXT_ROOT:-$(find_nearest_context)}"
    export CTX_WORKSPACE_ROOT="$PWD"

    # Context hierarchy as colon-separated path
    local hierarchy
    hierarchy=$(find_context_hierarchy | tr '\n' ':' | sed 's/:$//')
    export CTX_CONTEXT_PATH="$hierarchy"

    # Platform-specific paths (for Windows interop)
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        if command -v cygpath >/dev/null 2>&1; then
            export CTX_PROJECT_ROOT_WIN="$(cygpath -w "$CTX_PROJECT_ROOT")"
            export CTX_CONTEXT_ROOT_WIN="${CTX_CONTEXT_ROOT:+$(cygpath -w "$CTX_CONTEXT_ROOT")}"
        fi
    fi

    # Debug output if requested
    if [[ "${CTX_DEBUG:-}" == "true" ]]; then
        echo "CTX_HOME=$CTX_HOME" >&2
        echo "CTX_PROJECT_ROOT=$CTX_PROJECT_ROOT" >&2
        echo "CTX_CONTEXT_ROOT=$CTX_CONTEXT_ROOT" >&2
        echo "CTX_CONTEXT_PATH=$CTX_CONTEXT_PATH" >&2
    fi
}

# === Utility Functions ===

ctx_error() {
    echo "Error: $*" >&2
    return 1
}

ctx_warn() {
    echo "Warning: $*" >&2
}

ctx_info() {
    echo "$*"
}

# Check if context exists
has_context() {
    [[ -n "${CTX_CONTEXT_ROOT:-}" && -d "$CTX_CONTEXT_ROOT" ]]
}

# Get context file path with hierarchy search
get_context_file() {
    local filename="$1"
    local search_hierarchy="${2:-false}"

    if [[ "$search_hierarchy" == "true" ]]; then
        # Search through hierarchy
        IFS=':' read -ra contexts <<< "${CTX_CONTEXT_PATH:-}"
        for ctx in "${contexts[@]}"; do
            if [[ -f "$ctx/$filename" ]]; then
                echo "$ctx/$filename"
                return
            fi
        done
    else
        # Just use nearest context
        if [[ -f "$CTX_CONTEXT_ROOT/$filename" ]]; then
            echo "$CTX_CONTEXT_ROOT/$filename"
            return
        fi
    fi

    echo ""
}

# Merge JSON files from hierarchy (child overrides parent)
merge_json_hierarchy() {
    local filename="$1"
    local merged="{}"

    IFS=':' read -ra contexts <<< "${CTX_CONTEXT_PATH:-}"
    for ctx in "${contexts[@]}"; do
        if [[ -f "$ctx/$filename" ]]; then
            merged=$(jq -s '.[0] * .[1]' <(echo "$merged") "$ctx/$filename" 2>/dev/null || echo "$merged")
        fi
    done

    echo "$merged"
}

# Initialize environment on script load
setup_environment
