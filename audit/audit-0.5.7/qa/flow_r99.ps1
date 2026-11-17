A shell svc power stayon false | Out-Null
A shell settings put system screen_off_timeout 30000 | Out-Null
Log ("timeout=" + ((A shell settings get system screen_off_timeout) -join ''))
A shell cmd statusbar collapse | Out-Null
