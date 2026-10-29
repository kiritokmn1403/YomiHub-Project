$ua='Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36'
$refs=@{'i.hinhhinh.com'='https://truyenqqgo.com/';'i.hinhgg.com'='https://truyenqqgo.com/';'thumb.vtvdigital.org'='https://vtvgo.vn/';'storage-bravo.cuutruyen.net'='https://cuutruyen.net/';'imgs.anime47.best'='https://anime47.best/'}
foreach($u in Get-Content 'D:\Claude A.I\dev\x016\urls.txt'){ if(!$u){continue}; $h=([uri]$u).Host
 $a=& curl.exe -s -o NUL -m 20 -A $ua -w "%{http_code} %{content_type} %{size_download} srv=%{remote_ip}" $u 2>&1
 $b=& curl.exe -s -o NUL -m 20 -A $ua -e "https://$h/" -w "%{http_code}" $u 2>&1
 $c='-'; if($refs[$h]){ $c=& curl.exe -s -o NUL -m 20 -A $ua -e $refs[$h] -w "%{http_code}" $u 2>&1 }
 $sv=& curl.exe -s -I -m 15 -A $ua $u 2>&1 | Select-String -Pattern '^(server|cf-mitigated|location):' | ForEach-Object { $_.Line.Trim() }
 "$h | noref=$a | selfref=$b | siteref=$c | $($sv -join ' ; ')"
}
