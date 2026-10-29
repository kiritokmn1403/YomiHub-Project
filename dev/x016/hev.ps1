$ErrorActionPreference = 'Continue'
. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
$env:Path = "D:\yh\tools\git\cmd;D:\yh\tools\git\mingw64\bin;" + $env:Path
$d = 'D:\yh\hev'
if ($true) {
  if (Test-Path $d) { Remove-Item -Recurse -Force $d }
  & git.exe -c core.symlinks=true clone --depth 1 --recursive --shallow-submodules https://github.com/heiher/hev-socks5-tunnel $d 2>&1 | Select-Object -Last 5
}
Push-Location $d
& git.exe log -1 --format='%h %cd %s' 2>&1
& git.exe describe --tags 2>&1
Get-ChildItem | Select-Object Name
$ndk = 'D:\yh\tools\android-sdk\ndk\27.0.12077973'
& "$ndk\ndk-build.cmd" NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=Android.mk NDK_APPLICATION_MK=Application.mk "APP_ABI=armeabi-v7a arm64-v8a x86_64" APP_PLATFORM=android-23 "APP_CFLAGS=-O3 -DPKGNAME=com/kodjodevf/mangayomi -DCLASSNAME=YomiTun2Socks" -j8 2>&1 | Select-Object -Last 25
Get-ChildItem -Recurse libs | Select-Object FullName, Length
Pop-Location
