# usage: bash t.sh ext.js baseUrl 'plan-json' [rounds]
H="$HOME/mnt/YomiHub Project/dev/x020/h"; cd "$H"
R=${4:-3}
for i in $(seq 1 $R); do
  node run2.js "ext/$1" "$2" "$3" > out.txt 2>&1
  n=$(grep -c . missing.txt 2>/dev/null || echo 0)
  if [ "$n" = "0" ]; then break; fi
  echo "& 'D:\Claude A.I\dev\x020\h\fetch_missing.ps1'" | bash ../jb.sh fm_$RANDOM fast 170 | tail -12
done
cat out.txt | cut -c1-600
