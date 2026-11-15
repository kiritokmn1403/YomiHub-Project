$global:S="emulator-5554"
A push D:\yh\backup_test\Test_Anime_VOD.mp4 /sdcard/Download/YH_PC/YH_Video_Test.mp4 | Out-Null
A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/YH_PC/YH_Video_Test.mp4 | Out-Null
Log done
