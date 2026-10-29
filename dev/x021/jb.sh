# usage: bash jb.sh NAME fast|slow [waitsec] < body.ps1   (body is PowerShell); names get prefix y21_
K="$HOME/mnt/YomiHub Project"; J="$K/jobs"
N="y21_$1"; Q="$2"; W="${3:-170}"; D=pending_fast; [ "$Q" = slow ] && D=pending
TO=15; [ "$Q" = slow ] && TO=90
[ -n "$JTO" ] && TO=$JTO
rm -f "$J/done/$N.log"
{ printf '\xef\xbb\xbf# timeout: '"$TO"'\n'; cat; } | sed 's/$/\r/' > "$J/$D/$N.ps1"
bash "$K/dev/x021/jw.sh" "$1" "$W"
