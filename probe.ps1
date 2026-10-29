$o = "D:\Claude A.I\logs\probe.txt"
"where git: " + ((Get-Command git -ErrorAction SilentlyContinue).Source) | Out-File $o
"where flutter: " + ((Get-Command flutter -ErrorAction SilentlyContinue).Source) | Out-File $o -Append
"where java: " + ((Get-Command java -ErrorAction SilentlyContinue).Source) | Out-File $o -Append
foreach ($p in 'C:\Program Files\Git\cmd\git.exe','C:\Program Files (x86)\Git\cmd\git.exe',"$env:LOCALAPPDATA\Programs\Git\cmd\git.exe","$env:LOCALAPPDATA\Android\Sdk","C:\Program Files\Android\Android Studio","C:\src\flutter","C:\flutter","$env:USERPROFILE\flutter","C:\yh\tools","C:\yh") { "$p : " + (Test-Path $p) | Out-File $o -Append }
Get-ChildItem C:\ -Directory -ErrorAction SilentlyContinue | ForEach-Object { "C:\" + $_.Name } | Out-File $o -Append
(Measure-Command { & curl.exe -s -o NUL -r 0-5000000 https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip }).TotalSeconds | ForEach-Object { "5MB googleapis secs: $_" } | Out-File $o -Append
(Measure-Command { & curl.exe -s -o NUL -L -r 0-5000000 https://codeload.github.com/flutter/flutter/zip/refs/heads/stable }).TotalSeconds | ForEach-Object { "5MB codeload secs: $_" } | Out-File $o -Append
