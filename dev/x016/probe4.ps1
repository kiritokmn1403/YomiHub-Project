$o='D:\Claude A.I\dev\x016\probe'
$ua='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36'
& curl.exe -sL -m 30 -A $ua -o "$o\miyomi.js" "https://miyomi.app/assets/index-CYgTdx1u.js"
& curl.exe -sL -m 30 -A $ua -o "$o\drive_015.html" "https://drive.google.com/embeddedfolderview?id=1mw_9CjamZHeGKBdRlfEGYRW-MkfyT2fr"
$j = Get-Content "$o\miyomi.js" -Raw
[regex]::Matches($j,'https?://[A-Za-z0-9./_\-?=&%]+') | ForEach-Object { $_.Value } | Sort-Object -Unique | Where-Object { $_ -match 'api|json|supabase|github|raw|data|firebase' } | Select-Object -First 60
"len=$($j.Length)"
