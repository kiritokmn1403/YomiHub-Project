#!/bin/bash
# usage: submit.sh <jobname> <timeout-min> <bodyfile>   -> builds qa1_<jobname>.ps1 (BOM+CRLF), waits for log, prints it
R="$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
N="qa1r_$1"; T="$2"; B="$3"
rm -f "$R/jobs/done/$N.log"
{ printf '\xef\xbb\xbf# timeout: %s\n. "D:\\Claude A.I\\audit-0.5.7\\qa\\qa_lib.ps1"\n' "$T"; cat "$B"; } | sed 's/\r$//; s/$/\r/' > "$R/jobs/pending_fast/$N.ps1"
for i in $(seq 1 ${WAITS:-33}); do
  sleep 3
  if [ -f "$R/jobs/done/$N.log" ] && grep -aq "### EXIT" <(iconv -f utf-16le -t utf-8 "$R/jobs/done/$N.log" 2>/dev/null; cat "$R/jobs/done/$N.log" 2>/dev/null); then break; fi
done
L="$R/jobs/done/$N.log"
if head -c2 "$L" | xxd -p | grep -qi fffe; then iconv -f utf-16le -t utf-8 "$L"; else cat "$L"; fi | tr -d '\r'
