$EV="$QA\evidence\phone\p8f2"
A shell "cp /sdcard/YomiHub/mpv/mpv.conf /sdcard/YomiHub/mpv/mpv.conf.p8fbak" | Out-Null
A shell "rm -f /sdcard/YomiHub/p8f_mpv.log /sdcard/YomiHub/p8f_win.jpg /sdcard/YomiHub/p8f_vid.jpg; printf '\nlog-file=/sdcard/YomiHub/p8f_mpv.log\nmsg-level=all=v\n' >> /sdcard/YomiHub/mpv/mpv.conf" | Out-Null
A push "$QA\qa\p8f\p8f_diag.lua" /sdcard/YomiHub/mpv/scripts/p8f_diag.lua | Out-Null
try {
A shell cmd statusbar collapse | Out-Null
GoHome
TapText 'Th.m Tab 5' | Out-Null; Start-Sleep 3; Tap 700 1540; Start-Sleep 4; Tap 720 364; Start-Sleep 3
Tap 1080 2000; Log 'tapped Kungfu'
Start-Sleep 38; Shot "${TAG}_t38"
Tap 720 1300; Start-Sleep 1; Tap 105 112; Start-Sleep 3; Log (Fg)
} finally {
A shell "cp /sdcard/YomiHub/mpv/mpv.conf.p8fbak /sdcard/YomiHub/mpv/mpv.conf && rm /sdcard/YomiHub/mpv/mpv.conf.p8fbak; rm -f /sdcard/YomiHub/mpv/scripts/p8f_diag.lua" | Out-Null
}
A shell "cat /sdcard/YomiHub/mpv/mpv.conf; echo; ls -la /sdcard/YomiHub/mpv/mpv.conf /sdcard/YomiHub/mpv/scripts/ /sdcard/YomiHub/p8f_*"
A pull /sdcard/YomiHub/p8f_mpv.log "$EV\${TAG}_mpv.log" | Out-Null
A pull /sdcard/YomiHub/p8f_win.jpg "$EV\${TAG}_win.jpg" | Out-Null
A pull /sdcard/YomiHub/p8f_vid.jpg "$EV\${TAG}_vid.jpg" | Out-Null
A shell "rm -f /sdcard/YomiHub/p8f_mpv.log /sdcard/YomiHub/p8f_win.jpg /sdcard/YomiHub/p8f_vid.jpg" | Out-Null
