$EV="$QA\evidence\backup"
Tap 720 2638
Start-Sleep 4
Shot b4_after_create
Ui b4_after_create | Out-Null
Log ("FOCUS " + (A shell dumpsys window | Select-String mCurrentFocus))
