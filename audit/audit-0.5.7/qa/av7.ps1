$global:S='emulator-5554'; $EV="$QA\evidence\avd29"
A shell "grep -a 'Sao l' /sdcard/YomiHub/logs.txt | tail -n 3" | ForEach-Object { Log "APPLOG $_" }
A shell "ls /sdcard/YomiHub/" | ForEach-Object { Log "DIR $_" }
& adb -s 281038ac31217ece pull /sdcard/Download/YomiHub_test/Test_Anime_VOD.mp4 D:\yh\backup_test\Test_Anime_VOD.mp4 2>&1 | Out-Null
A shell mkdir -p "/sdcard/YomiHub/localanime/YH Video Test" | Out-Null
A push D:\yh\backup_test\Test_Anime_VOD.mp4 "/sdcard/YomiHub/localanime/YH Video Test/Tap 01.mp4" | Select-Object -Last 1 | ForEach-Object { Log "PUSH $_" }
