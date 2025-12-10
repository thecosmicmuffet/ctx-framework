#!/usr/bin/env bash
# ctx index - List context files with sizes and staleness
# Usage: ./ctx index [path]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_DIR="${1:-$(dirname "$SCRIPT_DIR")/.context}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
DARKYELLOW='\033[0;33m'
NC='\033[0m'

if [[ ! -d "$CONTEXT_DIR" ]]; then
    echo -e "${YELLOW}NO CONTEXT DIRECTORY FOUND${NC}"
    echo -e "${GRAY}Expected: $CONTEXT_DIR${NC}"
    echo ""
    echo -e "${GRAY}This may mean:${NC}"
    echo -e "${GRAY}  - You're in the wrong directory${NC}"
    echo -e "${GRAY}  - Context hasn't been initialized yet${NC}"
    echo -e "${GRAY}  - Specify a path: ./ctx index /path/to/.context${NC}"
    exit 1
fi

get_staleness() {
    local file="$1"
    local now=$(date +%s)
    local modified=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    local days=$(( (now - modified) / 86400 ))
    
    if [[ $days -eq 0 ]]; then
        echo "today|$GREEN"
    elif [[ $days -eq 1 ]]; then
        echo "1 day|$GREEN"
    elif [[ $days -le 7 ]]; then
        echo "$days days|$YELLOW"
    elif [[ $days -le 30 ]]; then
        echo "$days days|$DARKYELLOW"
    else
        echo "$days days|$RED"
    fi
}

get_line_count() {
    wc -l < "$1" 2>/dev/null | tr -d ' ' || echo "?"
}

echo ""
echo -e "${CYAN}CONTEXT INDEX: $CONTEXT_DIR${NC}"
echo -e "${GRAY}$(printf '=%.0s' {1..70})${NC}"
echo ""

total_lines=0
file_count=0
current_dir=""

# Find all files, sorted
while IFS= read -r file; do
    rel_path="${file#$CONTEXT_DIR/}"
    dir_part="$(dirname "$rel_path")"
    file_name="$(basename "$file")"
    
    # Print directory header if changed
    if [[ "$dir_part" != "$current_dir" ]]; then
        [[ -n "$current_dir" ]] && echo ""
        if [[ "$dir_part" == "." ]]; then
            echo -e "${YELLOW}/${NC}"
        else
            echo -e "${YELLOW}/$dir_part/${NC}"
        fi
        current_dir="$dir_part"
    fi
    
    lines=$(get_line_count "$file")
    staleness_info=$(get_staleness "$file")
    staleness_text="${staleness_info%%|*}"
    staleness_color="${staleness_info##*|}"
    modified=$(date -r "$file" "+%Y-%m-%d" 2>/dev/null || stat -c %y "$file" 2>/dev/null | cut -d' ' -f1)
    
    [[ "$lines" != "?" ]] && total_lines=$((total_lines + lines))
    file_count=$((file_count + 1))
    
    # Format output
    printf "  ${WHITE}%-28s${NC}" "$file_name"
    printf "${GRAY}%10s${NC}" "$lines lines"
    printf "   ${GRAY}%s${NC}   " "$modified"
    echo -e "${staleness_color}($staleness_text)${NC}"
    
done < <(find "$CONTEXT_DIR" -type f -name "*.md" -o -name "*.json" 2>/dev/null | sort)

echo ""
echo -e "${GRAY}$(printf '=%.0s' {1..70})${NC}"
estimated_tokens=$((total_lines * 13 / 10))  # ~1.3 tokens per line
echo -e "${CYAN}Total: $file_count files, ~$total_lines lines (~$estimated_tokens tokens est.)${NC}"
echo ""

# Suggest reading order
echo -e "${YELLOW}SUGGESTED READING ORDER:${NC}"
for priority_file in "projectObjectives.md" "changeLog.md" "README.md"; do
    found=$(find "$CONTEXT_DIR" -maxdepth 1 -name "$priority_file" 2>/dev/null)
    if [[ -n "$found" ]]; then
        lines=$(get_line_count "$found")
        staleness_info=$(get_staleness "$found")
        staleness_text="${staleness_info%%|*}"
        echo -e "${GRAY}  - $priority_file ($lines lines, $staleness_text old)${NC}"
    fi
done
echo ""
