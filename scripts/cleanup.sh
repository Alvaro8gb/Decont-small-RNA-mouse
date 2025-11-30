#!/bin/bash

# Usage examples:
#   bash scripts/cleanup.sh           # Removes all
#   bash scripts/cleanup.sh data log # Removes only data and logs
#   bash scripts/cleanup.sh out    # Removes only output


# Map argument keywords to directories
declare -A DIR_MAP=(
    ["data"]="data"
    ["res"]="res"
    ["out"]="out"
    ["log"]="log"
)

# If no arguments, remove all directories
if [ $# -eq 0 ]; then
    TARGETS=("${DIR_MAP[@]}")
else
    TARGETS=()
    for arg in "$@"; do
        if [[ -n "${DIR_MAP[$arg]}" ]]; then
            TARGETS+=("${DIR_MAP[$arg]}")
        else
            echo "Unknown argument: $arg"
        fi
    done
fi


# Remove selected directories
for dir in "${TARGETS[@]}"; do
    echo "Removing $dir"
    # Remove everything except .gitkeep
    find "$dir" -mindepth 1 ! -name ".gitkeep" -exec rm -rf {} +
done