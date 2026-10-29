$o='D:\Claude A.I\dev\x016\probe'
$ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36'
& curl.exe -sL -m 30 -A $ua -o "$o\wotaku_ext2.html" "https://wotaku.wiki/ext"
& curl.exe -sL -m 30 -A $ua -o "$o\drive_beta.html" "https://drive.google.com/embeddedfolderview?id=1EF_4MJQVxLpeKhRoMSctHBFPklPsmAdn"
$m = Get-Content "$o\miyomi.html" -Raw
[regex]::Matches($m,'src="([^"]+\.js)"') | ForEach-Object { $_.Groups[1].Value }
[regex]::Matches($m,'href="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 30
Get-ChildItem $o | Select-Object Name, Length
