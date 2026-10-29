# usage: bash fj.sh NAME [waitsec] < body.ps1
J="$HOME/mnt/Claude A.I/jobs"
N="$1"; W="${2:-150}"
{ printf '\xef\xbb\xbf# timeout: 10\n. '"'"'D:\\Claude A.I\\test\\adb_common.ps1'"'"'\n'; cat "$HOME/mnt/Claude A.I/dev/x014/fj_helpers.ps1"; cat; } | sed 's/$/\r/' > "$J/pending_fast/$N.ps1"
for i in $(seq 1 $((W/3))); do
  if [ -f "$J/done/$N.log" ] && iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | grep -q '### EXIT'; then break; fi
  sleep 3
done
iconv -f utf-16 -t utf-8 "$J/done/$N.log" 2>/dev/null | tr -d '\r' | cut -c1-300
