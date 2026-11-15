$env:QA_SERIAL='emulator-5554'; $global:S='emulator-5554'
$EV="$QA\evidence\avd29"
$apk = Get-ChildItem "$root\output\0.5.7" -Filter "YomiHub-0.5.7-x86_64.apk" | Sort-Object LastWriteTime | Select-Object -Last 1
Log "APK $($apk.Name) $($apk.Length) $($apk.LastWriteTime)"
A install -r -g $apk.FullName | Select-Object -Last 1 | ForEach-Object { Log "INSTALL $_" }
A shell monkey -p com.yomihub.app -c android.intent.category.LAUNCHER 1 | Out-Null
Start-Sleep 15
A shell "dumpsys window | grep mCurrentFocus" | ForEach-Object { Log "FOCUS $_" }
Shot a2_launch
Ui a2_launch | Out-Null
A logcat -d -s YomiHub | Select-Object -Last 5 | ForEach-Object { Log "LC $_" }
