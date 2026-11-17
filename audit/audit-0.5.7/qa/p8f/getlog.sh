#!/bin/bash
R="$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"; L="$R/jobs/done/p8f_$1.log"
for i in $(seq 1 ${WAITS:-33}); do
  if [ -f "$L" ] && (iconv -f utf-16le -t utf-8 "$L" 2>/dev/null; cat "$L") | grep -aq "### EXIT"; then break; fi; sleep 3
done
if head -c2 "$L" | xxd -p | grep -qi fffe; then iconv -f utf-16le -t utf-8 "$L"; else cat "$L"; fi | tr -d '\r' | tail -${TAILN:-200}
