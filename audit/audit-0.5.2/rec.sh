# usage: rec.sh start <name> <seconds> | rec.sh stop
cd "$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
if [ "$1" = start ]; then
bash audit-0.5.2/job.sh pending_fast rec_$2 2 >/dev/null <<PS
\$ff = "D:\yh\tools\ffmpeg-9.0.2-essentials_build\bin\ffmpeg.exe"
Start-Process -FilePath \$ff -ArgumentList "-y -f gdigrab -framerate 10 -draw_mouse 1 -i desktop -t $3 -vf scale=1280:-2 -c:v libx264 -preset ultrafast -crf 30 -pix_fmt yuv420p -movflags +frag_keyframe+empty_moov audit-0.5.2\qa\\$2.mp4" -WindowStyle Hidden
"rec started $2"
PS
bash audit-0.5.2/wait.sh rec_$2 60
else
bash audit-0.5.2/job.sh pending_fast rec_stop_$(date +%s) 2 >/dev/null <<'PS'
Get-Process ffmpeg -ErrorAction SilentlyContinue | ForEach-Object { $_.CloseMainWindow() | Out-Null; Stop-Process -Id $_.Id }
"stopped"
PS
fi
