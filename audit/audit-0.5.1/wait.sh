# usage: wait.sh <name> <max_seconds>
cd "$HOME/mnt/YomiHub-Project"
n=$1; m=${2:-170}; s=0
while [ $s -lt $m ]; do [ -f jobs/done/$n.log ] && iconv -f utf-16 -t utf-8 jobs/done/$n.log 2>/dev/null | grep -q "### EXIT" && break; sleep 3; s=$((s+3)); done
f=jobs/done/$n.log; [ -f $f ] || { echo "(chua xong)"; exit; }
(iconv -f utf-16 -t utf-8 $f 2>/dev/null || cat $f) | grep -v "^\s*$"
