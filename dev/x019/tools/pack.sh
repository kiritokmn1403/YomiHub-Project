#!/bin/bash
# pack.sh N -> /mnt/user-data/outputs/x019/p_NNN.tgz : all files changed vs base018 (+ ever-packed files)
set -e; cd /work/yh
N=$(printf %03d $1); OUT=/mnt/user-data/outputs/x019/p_$N.tgz
touch /work/tools/ever.txt
{ git diff --name-only --diff-filter=ACMR base018; git ls-files --others --exclude-standard; cat /work/tools/ever.txt; } | sort -u | while read f; do [ -f "$f" ] && echo "$f"; done > .yh_changed.txt
cp .yh_changed.txt /work/tools/ever.txt
git diff --name-only --diff-filter=D base018 > .yh_del19.txt || true
tar -czf $OUT -T .yh_changed.txt .yh_changed.txt .yh_del19.txt
echo "$OUT $(wc -l < .yh_changed.txt) files $(stat -c %s $OUT) bytes"
