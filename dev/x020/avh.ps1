$ua='Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Mobile Safari/537.36'
& curl.exe -s -m 30 -A $ua -D - -o NUL -H "Referer: https://animevietsub.nl/" "https://animevietsub.nl/anime-moi/?sort=view" | Select-String -Pattern 'HTTP/|set-cookie' 
