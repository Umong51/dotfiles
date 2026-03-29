#!/bin/bash
# Claude Code Statusline
# Shows: model | directory | context usage

input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
dir=$(echo "$input" | jq -r '.workspace.current_dir')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Context window display (shows USED percentage)
ctx=""
if [ -n "$remaining" ]; then
    rem=$(printf "%.0f" "$remaining")
    used=$((100 - rem))

    # Build progress bar (10 segments) - fills as context is consumed
    filled=$((used / 10))
    bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=filled; i<10; i++)); do bar+="░"; done

    # Color based on usage
    if [ "$used" -lt 50 ]; then
        ctx=$' \033[32m'"$bar $used%"$'\033[0m'
    elif [ "$used" -lt 65 ]; then
        ctx=$' \033[33m'"$bar $used%"$'\033[0m'
    elif [ "$used" -lt 80 ]; then
        ctx=$' \033[38;5;208m'"$bar $used%"$'\033[0m'
    else
        # Blinking red
        ctx=$' \033[5;31m'"$bar $used%"$'\033[0m'
    fi
fi

# Git branch
branch=""
if git -C "$dir" rev-parse --git-dir > /dev/null 2>&1; then
    b=$(git -C "$dir" symbolic-ref --short HEAD 2>/dev/null || git -C "$dir" rev-parse --short HEAD 2>/dev/null)
    [ -n "$b" ] && branch=$' \033[2m('"$b"$')\033[0m'
fi

# Output
dirname=$(basename "$dir")
printf '\033[2m%s\033[0m │ \033[2m%s\033[0m%s%s' "$model" "$dirname" "$branch" "$ctx"
