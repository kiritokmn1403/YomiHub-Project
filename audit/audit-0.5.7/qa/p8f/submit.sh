#!/bin/bash
# usage: submit.sh <jobname> <timeout-min> <bodyfile> ; env WAITS (x3s), NOLIB=1 to skip qa_lib
R="$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
N="p8f_$1"; T="$2"; B="$3"
rm -f "$R/jobs/done/$N.log"
{ printf '\xef\xbb\xbf# timeout: %s\n' "$T"; [ -z "$NOLIB" ] && printf '. "D:\\Claude A.I\\audit-0.5.7\\qa\\qa_lib.ps1"\n$EV="$QA\\evidence\\phone\\p8f"\n'; cat "$B"; } | sed 's/\r$//; s/$/\r/' > "$R/jobs/pending_fast/$N.ps1"
bash "$R/audit-0.5.7/qa/p8f/getlog.sh" "$1"
