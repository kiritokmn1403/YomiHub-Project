$EV="$QA\evidence\phone\qa1r"
A logcat -c | Out-Null
Tap 600 2140; Start-Sleep 15; Shot 'r04m_reader_a'; $null=Ui 'r04m_reader_a'
Tap 720 1480; Start-Sleep 2; Shot 'r04m_reader_b'; $null=Ui 'r04m_reader_b'
