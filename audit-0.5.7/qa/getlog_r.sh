#!/bin/bash
R="$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"; L="$R/jobs/done/qa1r_$1.log"
for i in $(seq 1 ${WAITS:-30}); do grep -aq "EXIT" "$L" 2>/dev/null && break; sleep 3; done
if head -c2 "$L" | xxd -p | grep -qi fffe; then iconv -f utf-16le -t utf-8 "$L"; else cat "$L"; fi | tr -d '\r'
