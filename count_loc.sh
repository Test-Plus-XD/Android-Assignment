#!/bin/bash

# Lines of Code Counter for Flutter PourRice App
# Counts non-empty, non-comment lines in Dart files
# Excludes generated files and comments

echo "=================================="
echo "  PourRice Flutter App - LOC Count"
echo "=================================="
echo ""

# Function to count LOC in a file
count_loc() {
    local file=$1
    # Count lines that are:
    # - Not empty
    # - Not pure comment lines (starting with //)
    # - Not pure comment blocks (/* ... */)
    grep -v '^\s*$' "$file" | grep -v '^\s*//' | grep -vcE '^\s*/\*|\*/'
}

# Categories
declare -A categories

# Main files
echo "Main Files:"
for file in lib/main.dart lib/config.dart lib/models.dart lib/firebase_options.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["main"]=$((${categories["main"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$file" "$loc"
    fi
done
echo ""

# Config files
echo "Config Files:"
for file in lib/config/*.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["config"]=$((${categories["config"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$file" "$loc"
    fi
done
echo ""

# Constants
echo "Constants:"
for file in lib/constants/*.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["constants"]=$((${categories["constants"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$file" "$loc"
    fi
done
echo ""

# Models
echo "Models:"
for file in lib/models/*.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["models"]=$((${categories["models"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$file" "$loc"
    fi
done
echo ""

# Services
echo "Services:"
for file in lib/services/*.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["services"]=$((${categories["services"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$file" "$loc"
    fi
done
echo ""

# Pages
echo "Pages:"
for file in lib/pages/*.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["pages"]=$((${categories["pages"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$file" "$loc"
    fi
done
echo ""

# Widgets
echo "Widgets:"
for dir in lib/widgets/*/; do
    if [ -d "$dir" ]; then
        echo "  $(basename $dir):"
        for file in "$dir"*.dart; do
            if [ -f "$file" ]; then
                loc=$(count_loc "$file")
                categories["widgets"]=$((${categories["widgets"]:-0} + loc))
                printf "    %-38s %5d lines\n" "$(basename $file)" "$loc"
            fi
        done
    fi
done

# Also count root widget files
for file in lib/widgets/*.dart; do
    if [ -f "$file" ]; then
        loc=$(count_loc "$file")
        categories["widgets"]=$((${categories["widgets"]:-0} + loc))
        printf "  %-40s %5d lines\n" "$(basename $file)" "$loc"
    fi
done
echo ""

# Summary
echo "=================================="
echo "  Summary by Category"
echo "=================================="
total=0
for category in main config constants models services pages widgets; do
    count=${categories[$category]:-0}
    total=$((total + count))
    printf "%-15s: %6d lines\n" "$category" "$count"
done
echo "=================================="
printf "%-15s: %6d lines\n" "TOTAL" "$total"
echo "=================================="
