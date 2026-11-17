function Mem($t){ $m = A shell "dumpsys meminfo com.yomihub.app | grep -E 'Graphics:|Native Heap:|TOTAL:'"; "MEM $t :: " + (($m -join ' ') -replace '\s+',' ') }
GoHome; Mem 'home'
TapText 'Duy.t Tab 4' | Out-Null; Start-Sleep 4
if(-not (TapText 'MangaDex')){ Tap 400 875 }; Start-Sleep 8
Tap 1020 181; Start-Sleep 2; A shell input text 'Shirley'; Start-Sleep 1; Key 66; Start-Sleep 9
Tap 360 1000; Start-Sleep 10; Mem 'detail'
TapText 'Ch\.11' | Out-Null
Start-Sleep 6; Mem 'reader_t6'
Start-Sleep 12; Mem 'reader_t18'
Start-Sleep 20; Mem 'reader_t38'
A shell "tail -c 600 /sdcard/YomiHub/logs.txt"
