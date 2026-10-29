# gb.sh N : extract bpN.tgz into bridge and build
cd "$HOME/mnt/YomiHub Project/dev/x021"; rm -rf bridge/yomihub_bridge/src; tar xzf $1.tgz -C bridge
echo '& "D:\Claude A.I\dev\x021\gr.ps1" "installDist"' | JTO=20 bash jb.sh gr_$1 fast 175 | grep -v "^System.Management\|^$\|Gradle 10\|warning-mode\|command_line_warnings\|Try:\|stacktrace\|--info\|--scan\|help.gradle\|Daemon\|single-use\|Problems report" | head -${2:-60}
