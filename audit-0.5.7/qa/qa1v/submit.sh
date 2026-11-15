#!/bin/bash
# usage: submit.sh <jobname> <timeout-min> <bodyfile>
R="$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
N="qa1v_$1"; T="$2"; B="$3"
rm -f "$R/jobs/done/$N.log"
{ printf '\xef\xbb\xbf# timeout: %s\n' "$T"; printf '. "D:\\Claude A.I\\audit-0.5.7\\qa\\qa_lib.ps1"\n$EV="$QA\\evidence\\phone\\qa1v"\n'; cat "$B"; } | sed 's/\r$//; s/$/\r/' > "$R/jobs/pending_fast/$N.ps1"
L="$R/jobs/done/$N.log"
for i in $(seq 1 ${WAITS:-50}); do
  if [ -f "$L" ] && (iconv -f utf-16le -t utf-8 "$L" 2>/dev/null; cat "$L") | grep -aq "### EXIT"; then break; fi; sleep 3
done
if head -c2 "$L" | xxd -p | grep -qi fffe; then iconv -f utf-16le -t utf-8 "$L"; else cat "$L"; fi | tr -d '\r' | tail -${TAILN:-80}
