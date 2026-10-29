# usage: bash wait.sh NAME [maxsec]
J="$HOME/mnt/Claude A.I/jobs"; N="$1"; W="${2:-170}"
for i in $(seq 1 $((W/5))); do
  if [ -f "$J/done/$N.log" ] && iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | grep -q '### EXIT'; then break; fi
  sleep 5
done
if [ -f "$J/done/$N.log" ]; then iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | tr -d '\r' | cut -c1-400; else echo "(not done yet)"; fi
