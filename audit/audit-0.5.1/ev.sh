getevent -pl 2>/dev/null | grep -B1 -A0 -i "name:" | grep -E "add device|name" | paste - - | grep -i -E "dex|keyboard|gpio|headset"
( getevent -lt > /data/local/tmp/ev.txt 2>&1 & echo $! > /data/local/tmp/ev.pid )
