#!/bin/bash
# usage: run.sh <name> <timeout-min> <bodyfile> ; job name q4_<name>, evidence in evidence/phone/q4
R="$HOME/mnt/YomiHub-Project"
N="q4_$1"; T="$2"; B="$3"
rm -f "$R/jobs/done/$N.log"
{ printf '\xef\xbb\xbf# timeout: %s\n. "D:\\Claude A.I\\audit-0.5.7\\qa\\qa_lib.ps1"\n$global:EV="$QA\\evidence\\phone\\q4"; New-Item -ItemType Directory -Force $EV | Out-Null\n' "$T"; cat "$B"; } | sed 's/\r$//; s/$/\r/' > "$R/jobs/pending_fast/$N.ps1"
for i in $(seq 1 ${WAITS:-55}); do
  sleep 3
  [ -f "$R/jobs/done/$N.log" ] && (iconv -f utf-16le -t utf-8 "$R/jobs/done/$N.log" 2>/dev/null; cat "$R/jobs/done/$N.log") | grep -aq "### EXIT" && break
done
L="$R/jobs/done/$N.log"
if head -c2 "$L" | xxd -p | grep -qi fffe; then iconv -f utf-16le -t utf-8 "$L"; else cat "$L"; fi | tr -d '\r' | tail -60
