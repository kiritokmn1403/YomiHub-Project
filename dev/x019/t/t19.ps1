. 'D:\Claude A.I\dev\x019\t\c.ps1'
Back 2; Back 2; Back 2; Back 2
TapText '^Browse' 3 | Out-Null
TapText 'Film & Movie Setting' 3 | Out-Null
TapText '^Source$' 3 | Out-Null
Labels 't19_src' | Select-String 'YouTube|FikFap' | Select-Object -First 4
TapText '^YouTube' 12 | Out-Null
Labels 't19_yt' | Select-Object -First 12
TapText '^Short' 25 | Out-Null
Shot 't19_short'
Labels 't19_short' | Select-Object -First 20
