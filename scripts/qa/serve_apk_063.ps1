# YomiHub 0.6.3: phat APK qua Wi-Fi noi bo de dien thoai (Xiaomi 15T) tai ve cai thu (tu dung sau 45 phut)
$f = 'D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project\output\0.6.3\YomiHub-0.6.3-arm64-v8a.apk'
$l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, 8765); $l.Start()
$end = (Get-Date).AddMinutes(45)
while ((Get-Date) -lt $end) {
  if (-not $l.Pending()) { Start-Sleep -Milliseconds 300; continue }
  $c = $l.AcceptTcpClient(); $s = $c.GetStream()
  try {
    $r = New-Object System.IO.StreamReader($s); $line = $r.ReadLine(); while (($h = $r.ReadLine()) -ne '' -and $h -ne $null) {}
    $fi = Get-Item $f
    if ($line -match ' /yomihub063\.apk ') {
      $hdr = "HTTP/1.1 200 OK`r`nContent-Type: application/vnd.android.package-archive`r`nContent-Length: $($fi.Length)`r`nContent-Disposition: attachment; filename=`"YomiHub-0.6.3-arm64-v8a.apk`"`r`nConnection: close`r`n`r`n"
      $b = [Text.Encoding]::ASCII.GetBytes($hdr); $s.Write($b,0,$b.Length)
      $fs = [IO.File]::OpenRead($f); $fs.CopyTo($s); $fs.Close()
    } else {
      $body = [Text.Encoding]::UTF8.GetBytes('<html><body style="font-size:48px"><a href="/yomihub063.apk">YomiHub 0.6.3 arm64 APK</a></body></html>')
      $hdr = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n"
      $b = [Text.Encoding]::ASCII.GetBytes($hdr); $s.Write($b,0,$b.Length); $s.Write($body,0,$body.Length)
    }
  } catch {} finally { $c.Close() }
}
$l.Stop()
