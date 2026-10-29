param([string]$tasks)
$env:JAVA_HOME = 'D:\yh\tools\jdk'
$env:GRADLE_USER_HOME = 'D:\yh\gradle-home'
$env:PATH = "D:\yh\tools\jdk\bin;" + $env:PATH
$g = Get-ChildItem 'D:\yh\gradle-home\wrapper\dists\gradle-9.3.1-bin' -Recurse -Filter gradle.bat | Select-Object -First 1
Set-Location 'D:\Claude A.I\dev\x021\bridge\yomihub_bridge'
& $g.FullName --no-daemon --console=plain ($tasks -split ' ') 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 120
"gradle exit $LASTEXITCODE"
