. 'D:\Claude A.I\dev\x019\t\c.ps1'
if (-not (EnsureEmulator)) { return }
Adb shell am start -a android.intent.action.VIEW -d '"yomihub://add-repo?url=https%3A%2F%2Fraw.githubusercontent.com%2FIReaderorg%2FIReader-extensions%2Frepov2%2Findex.min.json"' | Out-Null
Start-Sleep 5
Shot 't02_addrepo'
Labels 't02_addrepo' | Select-Object -First 30
