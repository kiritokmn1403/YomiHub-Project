$jar = Get-ChildItem "D:\A.I Project\yh\gradle-home\caches\modules-2\files-2.1\com.android.tools.build\aapt2" -Recurse -Filter "*.jar" | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Found jar: $jar"
$dest = "D:\A.I Project\yh\gradle-home\caches\9.3.1\transforms\c43eb51133547d34853f306bc54bdf16\workspace\transformed\aapt2-9.1.0-17472934-windows"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
& tar.exe -xf $jar -C $dest
Get-ChildItem $dest
