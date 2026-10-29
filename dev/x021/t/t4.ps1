. 'D:\Claude A.I\dev\x021\t\h.ps1'
Tap 300 1200 12
Shot2 't4_kotatsu_mdx'
L2 'mdx' | Select-Object -First 16
Crash | Select-String -Pattern 'kotatsu|Kotatsu|Error' | Select-Object -Last 10
