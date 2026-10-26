$o = 'D:\Claude A.I\test\emu6.txt'
& {
  . 'D:\Claude A.I\test\adb_common.ps1'
  Adb logcat -c
  TapText '^Để sau$' 4 | Out-Null
  Shot '10_home'; Labels '10_home'
  foreach ($tab in @('Duyệt', 'Thêm')) {
    if (TapText "^$tab" 4) { Shot "11_$tab"; Labels "11_$tab" }
  }
  foreach ($item in @('VPN', 'Trình duyệt', 'Hợp nhất', 'Sao lưu')) {
    if (TapText $item 4) { Shot "12_$item"; Labels "12_$item"; Back 3 }
  }
  Crash
} *>&1 | Out-File $o -Encoding utf8
