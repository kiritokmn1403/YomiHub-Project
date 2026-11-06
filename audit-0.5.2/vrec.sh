# vrec.sh start <name> [max_s] | vrec.sh stop
cd "$HOME/mnt/A.I Project - YomiHub Project/YomiHub-Project"
if [ "$1" = start ]; then
  bash audit-0.5.2/job.sh pending_fast vrec_$2 2 >/dev/null <<PS
Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File','audit-0.5.2\framerec.ps1','-name','$2','-max','${3:-900}') -WindowStyle Hidden
"vrec started $2"
PS
  bash audit-0.5.2/wait.sh vrec_$2 40
else
  : > audit-0.5.2/qa/STOPREC; echo "stop requested"
fi
