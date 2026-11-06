# usage: wait.sh <name> <max_seconds>
cd "$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
n=$1; m=${2:-170}; s=0
dec() { if head -c2 "$1" | od -An -tx1 | grep -q "ff fe"; then iconv -f utf-16 -t utf-8 "$1"; else cat "$1"; fi; }
while [ $s -lt $m ]; do [ -f jobs/done/$n.log ] && dec jobs/done/$n.log | grep -q "### EXIT" && break; sleep 3; s=$((s+3)); done
f=jobs/done/$n.log; [ -f $f ] || { echo "(chua xong)"; exit; }
dec $f | tr -d '\r' | grep -v "^\s*$"
