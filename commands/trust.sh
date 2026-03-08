#!/usr/bin/env bash
# ctx trust - Report confidence levels and stability states
# Usage: ./ctx trust [target] [path] [--detail]
#
# Shows which context can be trusted (fresh), needs forgiveness (stale),
# or has been honored (stable foundation)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"
PATH_ARG="${2}"
DETAIL=false

# Check for --detail flag
for arg in "$@"; do
    if [[ "$arg" == "--detail" ]]; then
        DETAIL=true
    fi
done

CONTEXT_DIR="${PATH_ARG:-$SCRIPT_DIR/.context}"

if [[ ! -d "$CONTEXT_DIR" ]]; then
    echo -e "\033[1;33mNO CONTEXT DIRECTORY FOUND\033[0m"
    echo -e "\033[0;90mExpected: $CONTEXT_DIR\033[0m"
    echo ""
    echo -e "\033[0;90mRun from project root or specify path\033[0m"
    exit 1
fi

# Staleness thresholds (configurable)
FRESH_DAYS=7
AGING_DAYS=30

# Get age in days for a file
get_file_age() {
    local file="$1"
    local modified=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    local now=$(date +%s)
    echo $(( (now - modified) / 86400 ))
}

# Get trust level for file age
get_trust_level() {
    local days=$1

    if [[ $days -le $FRESH_DAYS ]]; then
        echo "FRESH|Green|high|use directly|$days"
    elif [[ $days -le $AGING_DAYS ]]; then
        echo "AGING|Yellow|medium|validate if critical|$days"
    else
        echo "STALE|Red|low|verify before acting|$days"
    fi
}

# Format file entry
format_file_entry() {
    local file="$1"
    local trust="$2"
    local show_advice="$3"

    IFS='|' read -r level color confidence advice days <<< "$trust"

    local rel_path="${file#$CONTEXT_DIR}"
    rel_path="${rel_path#/}"

    local age_text
    if [[ $days -eq 0 ]]; then
        age_text="today"
    elif [[ $days -eq 1 ]]; then
        age_text="1 day"
    else
        age_text="$days days"
    fi

    echo -e "  ${rel_path} \033[0;90m($age_text old)\033[0m"

    if [[ "$show_advice" == "true" ]]; then
        echo -e "    \033[0;90m→ Confidence: $confidence - $advice\033[0m"
    fi
}

# Handle specific file
if [[ "$TARGET" != "all" && -n "$TARGET" ]]; then
    target_path="$CONTEXT_DIR/$TARGET"

    if [[ ! -f "$target_path" ]]; then
        echo -e "\033[0;31mFILE NOT FOUND: $TARGET\033[0m"
        echo -e "\033[0;90mPath checked: $target_path\033[0m"
        exit 1
    fi

    days=$(get_file_age "$target_path")
    trust=$(get_trust_level $days)
    IFS='|' read -r level color confidence advice file_days <<< "$trust"

    echo ""
    echo -e "\033[0;36mTRUST REPORT: $TARGET\033[0m"
    echo -e "\033[0;90m======================================================================\033[0m"
    echo ""

    case "$color" in
        Green) color_code="\033[0;32m" ;;
        Yellow) color_code="\033[1;33m" ;;
        Red) color_code="\033[0;31m" ;;
    esac

    echo -e "Status: ${color_code}${level}\033[0m"
    echo "Last modified: $(date -r "$target_path" '+%Y-%m-%d %H:%M' 2>/dev/null || stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$target_path")"
    echo "Age: $days days"
    echo -e "\033[0;90mConfidence: \033[0m${color_code}${confidence^^}\033[0m"
    echo ""
    echo -e "Recommendation: ${color_code}${advice}\033[0m"

    if [[ "$level" == "STALE" ]]; then
        echo ""
        echo -e "\033[1;33mThis file is stale. Consider:\033[0m"
        echo -e "\033[0;90m  1. Review contents for what's still valid\033[0m"
        echo -e "\033[0;90m  2. Update with current reality\033[0m"
        echo -e "\033[0;90m  3. Or run: ./ctx forgive $TARGET --reason '...'\033[0m"
    fi

    echo ""
    exit 0
fi

# Show all files grouped by trust level
echo ""
echo -e "\033[0;36mTRUST REPORT: $CONTEXT_DIR\033[0m"
echo -e "\033[0;90m======================================================================\033[0m"
echo ""

# Arrays for categorization
declare -a fresh_files=()
declare -a aging_files=()
declare -a stale_files=()
declare -a honored_files=()

# Find all markdown and json files
while IFS= read -r -d '' file; do
    # Skip forgiveness files
    if [[ "$file" =~ \.forgiveness ]]; then
        continue
    fi

    days=$(get_file_age "$file")
    trust=$(get_trust_level $days)
    IFS='|' read -r level _ _ _ _ <<< "$trust"

    # Check if in honored directory
    if [[ "$file" =~ /honored/ ]]; then
        honored_files+=("$file|$trust")
    else
        case "$level" in
            FRESH) fresh_files+=("$file|$trust") ;;
            AGING) aging_files+=("$file|$trust") ;;
            STALE) stale_files+=("$file|$trust") ;;
        esac
    fi
done < <(find "$CONTEXT_DIR" -type f \( -name "*.md" -o -name "*.json" \) -print0)

# Display fresh files
if [[ ${#fresh_files[@]} -gt 0 ]]; then
    echo -e "\033[0;32mFRESH \033[0;90m(high confidence - use directly)\033[0m"
    for entry in "${fresh_files[@]}"; do
        IFS='|' read -r file trust <<< "$entry"
        format_file_entry "$file" "$trust" "$DETAIL"
    done
    echo ""
fi

# Display aging files
if [[ ${#aging_files[@]} -gt 0 ]]; then
    echo -e "\033[1;33mAGING \033[0;90m(medium confidence - validate if critical)\033[0m"
    for entry in "${aging_files[@]}"; do
        IFS='|' read -r file trust <<< "$entry"
        format_file_entry "$file" "$trust" "$DETAIL"
    done
    echo ""
fi

# Display stale files
if [[ ${#stale_files[@]} -gt 0 ]]; then
    echo -e "\033[0;31mSTALE \033[0;90m(low confidence - verify before acting)\033[0m"
    for entry in "${stale_files[@]}"; do
        IFS='|' read -r file trust <<< "$entry"
        format_file_entry "$file" "$trust" "$DETAIL"
    done
    echo ""
fi

# Display honored files
if [[ ${#honored_files[@]} -gt 0 ]]; then
    echo -e "\033[0;36mHONORED \033[0;90m(stable foundation - historical lessons)\033[0m"
    for entry in "${honored_files[@]}"; do
        IFS='|' read -r file trust <<< "$entry"
        format_file_entry "$file" "$trust" "$DETAIL"
    done
    echo ""
fi

# Overall assessment
echo -e "\033[0;90m======================================================================\033[0m"

total_files=$((${#fresh_files[@]} + ${#aging_files[@]} + ${#stale_files[@]}))

if [[ ${#stale_files[@]} -gt $((total_files / 2)) ]]; then
    overall="LOW"
    overall_color="\033[0;31m"
elif [[ ${#fresh_files[@]} -gt $((total_files / 2)) ]]; then
    overall="HIGH"
    overall_color="\033[0;32m"
else
    overall="MEDIUM"
    overall_color="\033[1;33m"
fi

echo -e "\033[0;36mFiles: $total_files total \033[0;90m(${#fresh_files[@]} fresh, ${#aging_files[@]} aging, ${#stale_files[@]} stale)\033[0m"

if [[ ${#honored_files[@]} -gt 0 ]]; then
    echo -e "\033[0;36mHonored: ${#honored_files[@]} files in stable archive\033[0m"
fi

echo -e "\033[0;36mOverall confidence: ${overall_color}${overall}\033[0m"
echo ""

# Recommendations
if [[ ${#stale_files[@]} -gt 0 ]]; then
    echo -e "\033[1;33mRECOMMENDATIONS:\033[0m"
    echo -e "\033[0;90m  • Review stale files before making decisions based on them\033[0m"
    echo -e "\033[0;90m  • Update files that are still active, or\033[0m"
    echo -e "\033[0;90m  • Run: ./ctx forgive all --reason 'describe what happened'\033[0m"

    if [[ ${#stale_files[@]} -gt 3 ]]; then
        echo ""
        echo -e "\033[1;33m  Large drift detected. Consider:\033[0m"
        echo -e "\033[0;90m    1. What's still relevant? Update those files\033[0m"
        echo -e "\033[0;90m    2. What was learned? Run: ./ctx honor <file> --lesson '...'\033[0m"
        echo -e "\033[0;90m    3. Acknowledge the gap: ./ctx forgive all\033[0m"
    fi
fi

if [[ "$DETAIL" == "true" ]]; then
    echo ""
    echo -e "\033[1;33mTRUST LEVELS EXPLAINED:\033[0m"
    echo -e "\033[0;32m  FRESH (0-$FRESH_DAYS days): \033[0;90mQuote directly, assume accurate\033[0m"
    echo -e "\033[1;33m  AGING ($FRESH_DAYS-$AGING_DAYS days): \033[0;90mUse cautiously, note age when referencing\033[0m"
    echo -e "\033[0;31m  STALE (${AGING_DAYS}+ days): \033[0;90mTreat as historical, verify before acting\033[0m"
    echo -e "\033[0;36m  HONORED (archived): \033[0;90mExtracted lessons, stable reference\033[0m"
fi

echo ""
