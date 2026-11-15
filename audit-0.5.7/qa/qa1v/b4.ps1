foreach($y in 1450,1200){
  Back; Start-Sleep 2
  Tap 500 $y; Start-Sleep 12; Shot "b4_list_$y"; $ns=Ui "b4_list_$y"
}
