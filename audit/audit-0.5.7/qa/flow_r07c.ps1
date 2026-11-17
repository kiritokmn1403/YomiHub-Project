$EV="$QA\evidence\phone\qa1r"
A logcat -c | Out-Null
foreach($it in @(@('^H.p nh.t ti.n .ch','r07c_merge'),@('^VPN','r12_vpn_dns'),@('^Sao L','r07c_backup'))){
  if(TapText $it[0]){ Start-Sleep 4; Shot $it[1]; $null=Ui $it[1]; Back; Start-Sleep 2 } 
  if(-not (Find '^C.i .t')){ Swipe 720 2100 720 900 300; Start-Sleep 1 }
}
if(TapText '^C.i .t$'){ Start-Sleep 3; Shot 'r07c_settings'; $null=Ui 'r07c_settings' }
