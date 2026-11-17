$EV="$QA\evidence\backup"
New-Item -ItemType Directory -Force D:\yh\backup_test | Out-Null
A pull "/sdcard/Download/YomiHub_test/yomihub_2026-11-15_19_25_32.021787.backup" "D:\yh\backup_test\phone_note9.backup" | Out-Null
Log ("PC FILE " + (Get-Item D:\yh\backup_test\phone_note9.backup).Length)
A shell "tail -n 60 /sdcard/YomiHub/logs.txt" | Select-String "Sao" | ForEach-Object { Log $_.Line }
