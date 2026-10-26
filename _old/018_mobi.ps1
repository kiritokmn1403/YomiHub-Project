. 'D:\Claude A.I\common.ps1'
$ErrorActionPreference = 'Continue'
Copy-Item 'D:\Claude A.I\test\mobi\lib\mobi_to_epub_v2.dart' 'D:\Claude A.I\test\mobi\lib\mobi_to_epub.dart' -Force
Remove-Item 'D:\Claude A.I\test\mobi\lib\mobi_to_epub_v2.dart' -Force -ErrorAction SilentlyContinue
& curl.exe -sSL -m 300 -o 'D:\Claude A.I\fetch\pg1342_full.azw3' 'https://www.gutenberg.org/ebooks/1342.kf8.images' 2>&1
& curl.exe -sSL -m 300 -o 'D:\Claude A.I\fetch\pg84.azw3' 'https://www.gutenberg.org/ebooks/84.kf8.images' 2>&1
Get-ChildItem 'D:\Claude A.I\fetch' -Include *.azw3,*.mobi -Recurse | ForEach-Object { "$($_.Name) $($_.Length)" }
Set-Location 'D:\Claude A.I\test\mobi'
$files = Get-ChildItem 'D:\Claude A.I\fetch' -Include *.azw3,*.mobi -Recurse | ForEach-Object { $_.FullName }
& 'D:\yh\tools\flutter\bin\dart.bat' run bin/main.dart @files 'D:\Claude A.I\test\mobi\out' 2>&1 | ForEach-Object { "$_" }
