#!/bin/bash
# Consolidate 2 "ILLUSTRATIONS" folders into one, merging by subfolder (muscle group).

set -euo pipefail

SRC_DIR="/Users/saichetangrandhe/Downloads"
DEST="/Users/saichetangrandhe/Downloads/ILLUSTRATIONS ALL"

SOURCE_FOLDERS=(
  "$SRC_DIR/ILLUSTRATIONS"
  "$SRC_DIR/ILLUSTRATIONS 2"
)

# Verify all source folders exist
for src in "${SOURCE_FOLDERS[@]}"; do
  if [[ ! -d "$src" ]]; then
    echo "❌ Source folder not found: $src"
    exit 1
  fi
done

echo "Creating destination: $DEST"
mkdir -p "$DEST"

total_copied=0

for src in "${SOURCE_FOLDERS[@]}"; do
  echo ""
  echo "Processing: $(basename "$src")"

  # Iterate subfolders (muscle groups)
  for subfolder in "$src"/*/; do
    [[ ! -d "$subfolder" ]] && continue

    group_name="$(basename "$subfolder")"
    dest_sub="$DEST/$group_name"
    mkdir -p "$dest_sub"

    count=0
    for file in "$subfolder"*; do
      [[ ! -f "$file" ]] && continue
      fname="$(basename "$file")"

      # Skip .DS_Store
      [[ "$fname" == .DS_Store ]] && continue

      # Copy (skip if already exists)
      if [[ ! -f "$dest_sub/$fname" ]]; then
        cp "$file" "$dest_sub/$fname"
        ((count++))
      fi
    done

    ((total_copied += count))
    [[ $count -gt 0 ]] && echo "  $group_name: +$count files"
  done
done

echo ""
echo "========================================="
echo "Done! Total files copied: $total_copied"
echo ""
echo "Summary per folder:"
for sub in "$DEST"/*/; do
  [[ ! -d "$sub" ]] && continue
  name="$(basename "$sub")"
  cnt=$(find "$sub" -maxdepth 1 -type f | wc -l | tr -d ' ')
  echo "  $name: $cnt files"
done
echo "========================================="
