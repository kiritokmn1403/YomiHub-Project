# usage: bash jw.sh NAME [waitsec]  - wait for job y9_NAME log and print it
K="$HOME/mnt/YomiHub Project"; J="$K/jobs"; N="y9_$1"; W="${2:-170}"
for i in $(seq 1 $((W/3))); do
  if [ -f "$J/done/$N.log" ] && iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | grep -q '### EXIT'; then break; fi
  sleep 3
done
if [ -f "$J/done/$N.log" ] && iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | grep -q '### EXIT'; then iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | tr -d '\r' | cut -c1-400 | tail -${TAILN:-80}; else echo "(still running)"; fi
