# usage: bash fj5.sh NAME TIMEOUT_MIN [adb] < body.ps1   (submit only)
J="$HOME/mnt/Claude A.I/jobs"
N="$1"; T="${2:-10}"
{ printf '\xef\xbb\xbf# timeout: '"$T"'\n'; if [ "$3" = adb ]; then printf ". 'D:\\\\Claude A.I\\\\test\\\\adb_common.ps1'\n"; cat "$HOME/mnt/Claude A.I/dev/x014/fj_helpers.ps1"; fi; cat; } | sed 's/$/\r/' > "$J/pending_fast/$N.ps1"
echo submitted $N
