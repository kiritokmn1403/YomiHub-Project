A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Tap 720 364; Start-Sleep 3
A logcat -c | Out-Null
Tap 1080 2000; Start-Sleep 8; Shot 'v1_t8'
Start-Sleep 10; Shot 'v1_t18'; Tap 720 1300; Start-Sleep 1; Shot 'v1_t19_tap'; $null=Ui 'v1_t19'
Start-Sleep 10; Shot 'v1_t30'
A shell "dumpsys media.audio_flinger | grep -i -E 'yomihub|Standby|active' | head -8"
A shell "dumpsys audio | grep -i -A3 'players:' | head -12"
A shell "dumpsys SurfaceFlinger --list | grep -i yomihub"
A shell "dumpsys activity activities | grep -i -E 'yomihub.*(pip|pinned)|supportsPictureInPicture|mResumedActivity' | head"
A logcat -d > "$EV\v1_logcat_full.txt"
A shell "tail -c 1500 /sdcard/YomiHub/logs.txt"
A shell "ls -laR /sdcard/YomiHub/mpv | head -40"
Back; Start-Sleep 3; Shot 'v1_back'; Fg
A shell "dumpsys activity activities | grep -i -E 'pinned|PINNED|mResumedActivity' | head"
Get-Content "$EV\ui_v1_t19.txt" -Encoding UTF8
