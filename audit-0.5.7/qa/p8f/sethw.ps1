# set "Bo giai ma phan cung" to $HW (regex anchored), log before/after
$EV="$QA\evidence\phone\p8f2"
A shell cmd statusbar collapse | Out-Null
GoMore
TapText '^C.i ..t' | Out-Null; Start-Sleep 3
TapText '^Tr.nh ph.t' | Out-Null; Start-Sleep 3
TapText '^B. gi.i m. Gi' | Out-Null; Start-Sleep 3
$n=Find '^B. gi.i m. ph.n c.ng'; Log ("HWDEC BEFORE: " + (Lbl $n))
TapText '^B. gi.i m. ph.n c.ng' | Out-Null; Start-Sleep 2; $null=Ui "sethw_dlg"
TapText $HWPAT | Out-Null; Start-Sleep 2
$n=Find '^B. gi.i m. ph.n c.ng'; Log ("HWDEC AFTER: " + (Lbl $n))
Get-Content "$EV\ui_sethw_dlg.txt" -Encoding UTF8
