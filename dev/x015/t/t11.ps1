Tap 954 305 2
TapText "^Huỷ$" 2
& $ADB shell rm -f "/sdcard/YomiHub/Savior/x36xhzz.ts"
& $ADB shell mkdir -p "'/sdcard/YomiHub/local/Test Anime'"
& $ADB shell cp "'/sdcard/YomiHub/Savior/HTML Video.mp4'" "'/sdcard/YomiHub/local/Test Anime/Tap 1.mp4'"
& $ADB shell mkdir -p "'/sdcard/Mihon/downloads/MangaDex (EN)/Test Manga/Chapter 1'"
for ($i=1; $i -le 3; $i++) { & $ADB shell screencap -p "'/sdcard/Mihon/downloads/MangaDex (EN)/Test Manga/Chapter 1/00$i.png'" }
& $ADB shell ls -R /sdcard/Mihon /sdcard/YomiHub/local
Reset
Tap 202 2170 4
Shot 't11_film'
L 20
