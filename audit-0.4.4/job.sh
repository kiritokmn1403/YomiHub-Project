#!/bin/bash
# usage: job.sh name < script   -> writes jobs/pending_fast/name.ps1 with UTF-8 BOM
J="$HOME/mnt/YomiHub-Project/jobs/${2:-pending_fast}"
{ printf '\xef\xbb\xbf'; cat; } > "$J/$1.ps1"
