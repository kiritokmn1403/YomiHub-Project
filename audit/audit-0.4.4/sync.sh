#!/bin/bash
# copies every file in changed_files.txt from overlay into both build trees
R="$HOME/mnt/YomiHub-Project"; Y="$HOME/mnt/yh"; n=0
while read -r f; do [ -z "$f" ] && continue
  for b in "$Y/build/mangayomi" "$Y/buildwin/mangayomi"; do
    mkdir -p "$(dirname "$b/$f")"; cp "$R/overlay/$f" "$b/$f" && n=$((n+1)); done
done < "$R/audit-0.4.4/changed_files.txt"; echo "synced $n copies"
