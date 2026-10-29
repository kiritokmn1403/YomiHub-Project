# usage: bash st.sh NAME "powershell commands using c.ps1 helpers"
cd "$HOME/mnt/YomiHub Project/dev/x020"
printf '%s\n' "$2" > t/cmd_$1.txt
echo "& 'D:\Claude A.I\dev\x020\t\s.ps1' -cmd ([IO.File]::ReadAllText('D:\Claude A.I\dev\x020\t\cmd_$1.txt'))" | JTO=10 bash jb.sh st_$1 fast ${3:-120} | grep -v "LocalLibraryScanner\|^10-07.*I/flutter.*Impeller\|IsarCore\|TorService" | tail -${4:-60}
