# YomiHub 0.5.6.1 A6: dựng lại flutter_embedding_release-yh23.jar (engine 692136cb) với kiểm tra phiên bản
# cho các lời gọi API 24: 4 lớp từ 0.4.3 (PathUtils, LocalizationPlugin, TextInputPlugin, AccessibilityViewEmbedder)
# + AccessibilityBridge (setImportantForAccessibility) + MouseCursorPlugin (PointerIcon) - A6 0.5.6.1.
$ErrorActionPreference = 'Continue'
$E = Split-Path -Parent $MyInvocation.MyCommand.Path
$G = 'D:\yh\gradle-home\caches\modules-2\files-2.1'
$emb = Get-ChildItem "$G\io.flutter\flutter_embedding_release\1.0.0-692136cb6582dbfc5af3fb33c2515a069f2f66d0" -Recurse -Filter *.jar | Where-Object { $_.Name -notmatch 'sources' } | Select-Object -First 1
$ann = Get-ChildItem "$G\androidx.annotation" -Recurse -Filter "annotation-jvm-*.jar" | Where-Object { $_.Name -notmatch 'sources' } | Sort-Object Name | Select-Object -Last 1
$coreAar = Get-ChildItem "$G\androidx.core\core" -Recurse -Filter "core-1.*.aar" | Where-Object { $_.BaseName -match '^core-1\.\d+\.\d+$' } | Sort-Object { [version]($_.BaseName -replace '^core-','') } | Select-Object -Last 1
$tmp = Join-Path $env:TEMP 'yh_a6_emb'; Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue; New-Item -ItemType Directory -Force "$tmp\classes","$tmp\core" | Out-Null
& tar.exe -xf $coreAar.FullName -C "$tmp\core" classes.jar
$cp = @('D:\yh\tools\android-sdk\platforms\android-36\android.jar', $emb.FullName, $ann.FullName, "$tmp\core\classes.jar") -join ';'
"emb=$($emb.FullName)`nann=$($ann.FullName)`ncore=$($coreAar.FullName)"
$srcs = Get-ChildItem "$E\src" -Recurse -Filter *.java | ForEach-Object { $_.FullName }
& 'D:\yh\tools\jdk\bin\javac.exe' -nowarn -proc:none --release 11 -encoding UTF-8 -cp $cp -d "$tmp\classes" @srcs 2>&1 | Where-Object { $_ -notmatch '^Note:' }
"javac exit $LASTEXITCODE"
if ($LASTEXITCODE -ne 0) { exit 1 }
$cls = Get-ChildItem "$tmp\classes" -Recurse -Filter *.class | ForEach-Object { $_.FullName.Substring("$tmp\classes\".Length) }
"$($cls.Count) lớp: $(($cls | ForEach-Object { Split-Path $_ -Leaf }) -join ' ')"
$out = Join-Path $E 'flutter_embedding_release-yh23.jar'
Copy-Item $emb.FullName "$out.new" -Force
Push-Location "$tmp\classes"
& 'D:\yh\tools\jdk\bin\jar.exe' uf "$out.new" @cls
$rc = $LASTEXITCODE
Pop-Location
if ($rc -ne 0) { "jar exit $rc"; exit 1 }
Move-Item "$out.new" $out -Force
"jar OK size $((Get-Item $out).Length) sha256 $((Get-FileHash $out).Hash.ToLower())"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
