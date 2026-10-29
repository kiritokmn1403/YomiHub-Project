$o='D:\Claude A.I\dev\x016\probe'
$k='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFpanJ1b2RyZWF6dWljYmN5aHZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA3MDkwMjUsImV4cCI6MjA4NjI4NTAyNX0.vV3oEwvZrQdCmgMRT9EVZrSP9sU3g0XcSmojThx0opE'
& curl.exe -sL -m 30 -H "apikey: $k" -H "Authorization: Bearer $k" -o "$o\miyomi_ext.json" "https://miyomi-api.supabase.co/rest/v1/extensions?select=name,auto_url,manual_url,types,compatible_with,region,language,short_description,updated_at&status=eq.approved&order=name"
(Get-Item "$o\miyomi_ext.json").Length
& curl.exe -sL -m 30 -o "$o\drive_015.html" "https://drive.google.com/embeddedfolderview?id=1mw_9CjamZHeGKBdRlfEGYRW-MkfyT2fr"
