#!/bin/bash
# usage: bk.sh relpath...  (relative to overlay) - backs up original once, records in changed_files.txt
R="$HOME/mnt/YomiHub-Project"; A="$R/audit-0.4.4"
for f in "$@"; do
  if [ -f "$R/overlay/$f" ] && [ ! -e "$A/before/$f" ]; then mkdir -p "$(dirname "$A/before/$f")"; cp -p "$R/overlay/$f" "$A/before/$f"; fi
  [ -f "$R/overlay/$f" ] || { mkdir -p "$(dirname "$A/before/$f")"; touch "$A/before/$f.NEW"; }
  grep -qxF "$f" "$A/changed_files.txt" 2>/dev/null || echo "$f" >> "$A/changed_files.txt"
done
