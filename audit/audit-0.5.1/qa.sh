# usage: qa.sh <jobname> <wait_s> cmd1 cmd2 ...
cd "$HOME/mnt/YomiHub-Project"
n=$1; w=$2; shift 2
args=""; for c in "$@"; do args="$args,\"$c\""; done; args=${args#,}
{ printf '\xef\xbb\xbf'; echo "# timeout: 15"; echo '$K = "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"'; echo "& \"\$K\\qa051.ps1\" -cmds $args"; } > jobs/pending_fast/$n.ps1
for i in $(seq 1 $((w/3+40))); do sleep 3; [ -f jobs/done/$n.log ] && grep -q "### EXIT" <(iconv -f utf-16 -t utf-8 jobs/done/$n.log 2>/dev/null) && break; done
iconv -f utf-16 -t utf-8 jobs/done/$n.log 2>/dev/null | grep -v "^\s*$" | grep -v "^At \|^+ \|CategoryInfo\|FullyQualified\|function A"
