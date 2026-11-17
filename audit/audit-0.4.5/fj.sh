#!/bin/bash
# fj.sh name [wait_s] < script.ps1 : queue fast job, wait for its log, print it
R="$HOME/mnt/YomiHub-Project"; J="$R/jobs"
{ printf '\xef\xbb\xbf'; cat; } > "$J/pending_fast/$1.ps1"
W=${2:-60}; for i in $(seq 1 $W); do
  if [ -f "$J/done/$1.log" ] && grep -q '### EXIT' "$J/done/$1.log" 2>/dev/null; then break; fi; sleep 1; done
python3 -c "import sys;b=open(sys.argv[1],'rb').read();print(b.replace(b'\\xff\\xfe',b'').replace(b'\\x00',b'').decode('utf-8','replace'))" "$J/done/$1.log" 2>/dev/null || echo "(no log yet)"
