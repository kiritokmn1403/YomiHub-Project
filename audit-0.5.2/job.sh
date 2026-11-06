# usage: job.sh <pending|pending_fast> <name> <timeout_min>  (PowerShell body on stdin)
cd "$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
q=$1; n=$2; t=$3
{ printf '\xef\xbb\xbf'; echo "# timeout: $t"; echo '$ErrorActionPreference="Continue"; Set-Location "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"'; cat; } > jobs/$q/$n.ps1
echo queued $q/$n
