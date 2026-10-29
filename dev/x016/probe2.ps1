$o='D:\Claude A.I\dev\x016\probe'
$ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36'
& curl.exe -sL -m 30 -A $ua -o "$o\drive_embed.html" "https://drive.google.com/embeddedfolderview?id=16PCPorl1Ae9nmKMMWAC3Oz1rp_w9tH__"
& curl.exe -sL -m 30 -A $ua -o "$o\wotaku.html" "https://wotaku.wiki/"
& curl.exe -sL -m 30 -A $ua -o "$o\miyomi.html" "https://miyomi.app/"
& curl.exe -sL -m 30 -A $ua -o "$o\wotaku_ext.html" "https://wotaku.wiki/guides/ext/mihon"
& curl.exe -sL -m 30 -A $ua -o "$o\miyomi_ext.html" "https://miyomi.app/extensions"
Get-ChildItem $o | Select-Object Name, Length
