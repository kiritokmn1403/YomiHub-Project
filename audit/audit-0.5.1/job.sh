# usage: job.sh <queue: pending|pending_fast> <name> <timeout_min> <<'PS' ... PS   (PowerShell body on stdin)
cd "$HOME/mnt/YomiHub-Project"
q=$1; n=$2; t=$3
{ printf '\xef\xbb\xbf'; echo "# timeout: $t"; cat; } > jobs/$q/$n.ps1
