. 'D:\Claude A.I\dev\x019\t\c.ps1'
TapText '^(Thêm|Add)$' 8 | Out-Null
Shot 't03_after_add'
Labels 't03_after_add' | Select-Object -First 15
TapText '^Browse' 4 | Out-Null
Labels 't03_browse' | Select-Object -First 30
