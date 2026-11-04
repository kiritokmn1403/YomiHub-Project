Set-Location "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"
$env:GCM_INTERACTIVE = 'never'; $env:GIT_TERMINAL_PROMPT = '0'
"--- fetch"; git fetch origin main 2>&1 | ForEach-Object { "$_" }
git status -sb | Select-Object -First 1
git add -A
"--- staged:"; git diff --cached --stat | Select-Object -Last 3
"--- secrets check:"; git diff --cached --name-only | Select-String -Pattern '\.jks$|keystore|password|\.apk$|\.exe$|\.zip$|yomi_ls|/qa/' | ForEach-Object { "BLOCKED? $_" }
$mf = "$env:TEMP\yh051_commit.txt"
$msg = "release: YomiHub 0.5.1 (0.5.1+43)`n`n- local folders: find Aniyomi/Nekoyomi/Mihon/Mangayomi downloads 2-4 levels deep, episode folders, skip *_tmp, autobackup, mpv-config, .bk.zip; dedupe nested copies`n- Android 7-10: request READ/WRITE storage (+ requestLegacyExternalStorage) instead of MANAGE_EXTERNAL_STORAGE only`n- background storage prompt asked once (after YomiPrefs is open); user actions still ask`n- AppLogger falls back to the app folder; log screen parses in a background isolate, never spins forever`n- APK inspector (Settings > Browse) built on Decode & Extract: AXML decoder + DEX reader in Dart (read-only)`n- perf: merge hint, Kotatsu start-up, Aidoku/LNReader refresh and source attribution use light async Isar queries`n- vBook runtime: fetch retry + real cause in errors; vBook-only label on its own line; clear 404 message`n- repo network warnings once per host; corrupt EPUB skipped during local scan`n- 18 missing Project GitHub links; 18-language strings; tests yh_051_test.dart`n- TECHNICAL_UPDATE_NOTES 0.5.1; README links to v0.5.1`n`nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`nClaude-Session: https://claude.ai/code/session_01C7DNQDNQ98thQQ5Du9C9St`n"
[IO.File]::WriteAllText($mf, $msg, (New-Object Text.UTF8Encoding($false)))
"--- commit"; git commit -F $mf 2>&1 | Select-Object -First 3
"--- push"; git push origin main 2>&1 | ForEach-Object { "$_" } | Select-Object -Last 3
"--- verify"; git status -sb | Select-Object -First 2
"remote: " + (git ls-remote origin refs/heads/main); "local:  " + (git rev-parse HEAD)
