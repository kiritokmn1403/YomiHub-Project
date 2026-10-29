. 'D:\Claude A.I\dev\x021\t\h.ps1'
$xml = Get-UiXml
[regex]::Matches($xml, 'NAF="true"[^>]*bounds="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 6
