#!/usr/bin/env bash
# ctx search - Wedge-style term search across context files
# Usage: ./ctx search <term> [path] [--depth N] [--expand] [--case] [--full]
#
# Returns matches with surrounding context and expansion hints

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SEARCH_TERM=""
PATH_ARG=""
DEPTH=2
EXPAND=false
CASE_SENSITIVE=false
FULL=false

# Parse arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --depth)
            DEPTH="$2"
            shift 2
            ;;
        --expand)
            EXPAND=true
            shift
            ;;
        --case)
            CASE_SENSITIVE=true
            shift
            ;;
        --full)
            FULL=true
            shift
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${POSITIONAL_ARGS[@]}"

SEARCH_TERM="$1"
PATH_ARG="$2"

if [[ -z "$SEARCH_TERM" ]]; then
    echo -e "\033[0;31mERROR: Search term required\033[0m"
    echo ""
    echo "Usage: ./ctx search <term> [path] [--depth N] [--expand] [--case] [--full]"
    exit 1
fi

CONTEXT_DIR="${PATH_ARG:-$SCRIPT_DIR/.context}"

# Normalize path - convert to absolute and resolve
if [[ -d "$CONTEXT_DIR" ]]; then
    CONTEXT_DIR="$(cd "$CONTEXT_DIR" && pwd)"
fi

if [[ ! -d "$CONTEXT_DIR" ]]; then
    echo -e "\033[1;33mNO CONTEXT DIRECTORY FOUND\033[0m"
    echo -e "\033[0;90mExpected: $CONTEXT_DIR\033[0m"
    echo ""
    echo -e "\033[0;90mSpecify a path with: ./ctx search term /path/to/.context\033[0m"
    exit 1
fi

# Validate depth parameter
if [[ $DEPTH -lt 0 || $DEPTH -gt 10 ]]; then
    echo -e "\033[0;31mERROR: --depth must be between 0 and 10\033[0m"
    exit 1
fi

# Build grep options
GREP_OPTS=""
if [[ "$CASE_SENSITIVE" == "false" ]]; then
    GREP_OPTS="-i"
fi

echo ""
echo -e "\033[0;36mSEARCH: \"$SEARCH_TERM\" in $CONTEXT_DIR\033[0m"
echo ""

# Temporary files to store results
TEMP_FILE=$(mktemp)
RESULTS_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE" "$RESULTS_FILE"' EXIT

# Find all matching files first
declare -a files_with_matches
while IFS= read -r -d $'\0' file; do
    if grep -q $GREP_OPTS "$SEARCH_TERM" "$file" 2>/dev/null; then
        files_with_matches+=("$file")
    fi
done < <(find "$CONTEXT_DIR" -type f \( -name "*.md" -o -name "*.json" \) -print0)

if [[ ${#files_with_matches[@]} -eq 0 ]]; then
    echo -e "\033[0;90mNo matches found.\033[0m"
    exit 1
fi

# Process each file
total_matches=0
file_count=${#files_with_matches[@]}
declare -a nearby_terms

for file in "${files_with_matches[@]}"; do
    relative_path="${file#$CONTEXT_DIR}"
    relative_path="${relative_path#/}"

    # Get all matches with line numbers and context
    declare -a match_lines
    declare -a all_lines

    # Read file into array
    mapfile -t all_lines < "$file"
    total_file_lines=${#all_lines[@]}

    # Find matching line numbers
    match_line_nums=()
    line_num=0
    if [[ "$CASE_SENSITIVE" == "false" ]]; then
        search_pattern="${SEARCH_TERM,,}"  # lowercase for comparison
        for line in "${all_lines[@]}"; do
            ((line_num++)) || true
            line_lower="${line,,}"
            if [[ "$line_lower" == *"$search_pattern"* ]]; then
                match_line_nums+=($line_num)
            fi
        done
    else
        for line in "${all_lines[@]}"; do
            ((line_num++)) || true
            if [[ "$line" == *"$SEARCH_TERM"* ]]; then
                match_line_nums+=($line_num)
            fi
        done
    fi

    match_count=${#match_line_nums[@]}
    total_matches=$((total_matches + match_count))

    # Skip file if no matches found
    if [[ $match_count -eq 0 ]]; then
        continue
    fi

    # Display matches (limit to 3 unless --full)
    display_count=$match_count
    if [[ "$FULL" == "false" && $match_count -gt 3 ]]; then
        display_count=3
    fi

    for ((i=0; i<display_count; i++)); do
        match_line_num=${match_line_nums[$i]}

        # Show file:line header
        echo -e "\033[1;33m$relative_path:$match_line_num\033[0m"

        # Calculate context range
        start_line=$((match_line_num - DEPTH))
        end_line=$((match_line_num + DEPTH))

        if [[ $start_line -lt 1 ]]; then
            start_line=1
        fi
        if [[ $end_line -gt $total_file_lines ]]; then
            end_line=$total_file_lines
        fi

        # Collect context for expansion
        context_text=""

        # Display lines with context
        for ((line_idx=start_line; line_idx<=end_line; line_idx++)); do
            line_content="${all_lines[$line_idx-1]}"

            if [[ $line_idx -eq $match_line_num ]]; then
                printf "\033[1;37m> %3d| %s\033[0m\n" "$line_idx" "$line_content"
                context_text+="$line_content "
            else
                printf "\033[0;90m  %3d| %s\033[0m\n" "$line_idx" "$line_content"
                context_text+="$line_content "
            fi
        done

        # Extract nearby terms for expansion
        if [[ "$EXPAND" == "true" ]]; then
            # Extract word-like identifiers
            words=$(echo "$context_text" | grep -oE '\b[A-Za-z][A-Za-z0-9_-]*\b' || true)
            for word in $words; do
                if [[ ${#word} -gt 3 && "$word" != "$SEARCH_TERM" ]]; then
                    nearby_terms+=("$word")
                fi
            done
        fi

        echo ""
    done

    # If more matches exist, show count
    if [[ "$FULL" == "false" && $match_count -gt 3 ]]; then
        echo -e "\033[0;90m  ... and $((match_count - 3)) more matches in this file\033[0m"
        echo ""
    fi
done

echo -e "\033[0;90m======================================================================\033[0m"
echo -e "\033[0;36mFound $total_matches matches in $file_count files.\033[0m"

# Show nearby terms if --expand
if [[ "$EXPAND" == "true" && ${#nearby_terms[@]} -gt 0 ]]; then
    # Count term frequency and get top 8
    unique_terms=$(printf '%s\n' "${nearby_terms[@]}" | sort | uniq -c | sort -rn | head -8 | awk '{print $2}' | tr '\n' ',' | sed 's/,/, /g' | sed 's/, $//')
    echo -e "\033[0;90mNearby terms: [$unique_terms]\033[0m"
fi

echo ""
exit 0
