# YomiHub A6: hàm dùng chung cho các job thử Android 6 (AVD OOS_Android6_API23, cổng 5580)
$root='D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project'; . "$root\common.ps1"; $ErrorActionPreference='Continue'
$A6="$root\audit-0.5.7\android6"; $EV="$A6\evidence"; New-Item -ItemType Directory -Force $EV,"$A6\work" | Out-Null
$SDK='D:\yh\tools\android-sdk'; $SDK2='C:\Users\nguye\AppData\Local\Android\Sdk'
$BT=(Get-ChildItem "$SDK\build-tools" | Sort-Object Name | Select-Object -Last 1).FullName
$S='emulator-5580'; if(-not $script:EmuExtra){ $script:EmuExtra='' }
function A { & "$SDK\platform-tools\adb.exe" -s $S @args }
function EmuUp {
  if(-not (((& "$SDK\platform-tools\adb.exe" devices) -join ' ') -match "$S\s+device")){
    $env:ANDROID_SDK_ROOT=$SDK2
    $emu="$SDK2\emulator\emulator.exe"
    Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine="cmd.exe /c `"`"$emu`" -avd OOS_Android6_API23 -port 5580 -memory 2048 -no-snapshot-save -no-boot-anim -no-audio $script:EmuExtra -gpu swiftshader_indirect > `"$EV\emu.log`" 2>&1`""} | Out-Null
    for($i=0;$i -lt 80;$i++){ Start-Sleep 3; if(((& "$SDK\platform-tools\adb.exe" devices) -join ' ') -match "$S\s+device"){ if(((A shell getprop sys.boot_completed 2>&1) -join '').Trim() -eq '1'){break} } }
    Start-Sleep 8
  }
  "sdk=$((A shell getprop ro.build.version.sdk) -join '') abi=$((A shell getprop ro.product.cpu.abi) -join '') kernel=$((A shell uname -r) -join '')"
}
function Shot($n){ A shell screencap -p /sdcard/q.png 2>&1 | Out-Null; A pull /sdcard/q.png "$EV\$n.png" 2>&1 | Out-Null; "shot $n $(Test-Path "$EV\$n.png")" }
function Sign($in,$out){
  $ks="$A6\work\debug.keystore"
  if(-not (Test-Path $ks)){ & keytool -genkeypair -keystore $ks -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" 2>&1 | Out-Null }
  Remove-Item $out -ErrorAction SilentlyContinue
  & "$BT\zipalign.exe" -p -f 4 $in $out; "zipalign $LASTEXITCODE"
  & "$BT\apksigner.bat" sign --ks $ks --ks-pass pass:android --key-pass pass:android $out 2>&1; "apksigner $LASTEXITCODE"
}
function Run($tag,[int[]]$waits=@(4,8,15)){
  A logcat -c
  A shell input keyevent 224; A shell input keyevent 82
  A shell am start -n com.yomihub.app/com.kodjodevf.mangayomi.MainActivity | Out-String
  $t=0; foreach($w in $waits){ Start-Sleep $w; $t+=$w; Shot "${tag}_${t}s" }
  A logcat -d -v time | Out-File "$EV\${tag}_logcat.txt" -Encoding utf8
  "proc=$(((A shell ps) | Select-String 'com.yomihub.app') -join ' | ')"
}
function EmuKill { A emu kill 2>&1 | Out-Null; Start-Sleep 8 }
function Lock($who){ $f="$root\audit-0.5.6\coordination\BUILD_LOCK.txt"; $c=(Get-Content $f -Raw -ErrorAction SilentlyContinue); if($c -and $c.Trim().Trim([char]0xFEFF)){ return $false }; Set-Content $f $who -Encoding utf8; return $true }
function Unlock { Set-Content "$root\audit-0.5.6\coordination\BUILD_LOCK.txt" '' -NoNewline }
