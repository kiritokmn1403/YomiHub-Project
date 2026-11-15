. "D:\Claude A.I\jobs\q057_lib.ps1"
$files = @(
 'lib\utils\image_load_timeout.dart',
 'lib\modules\manga\reader\subsampling_scale_image_view\src\ffi_image_decoder.dart',
 'lib\modules\manga\reader\subsampling_scale_image_view\src\subsampling_scale_image_view.dart',
 'lib\modules\manga\reader\subsampling_scale_image_view\src\min_subsampling_image_view.dart',
 'lib\modules\manga\reader\widgets\reader_page_content.dart',
 'lib\yomihub\player\resume_policy.dart',
 'lib\yomihub\player\yomi_pip.dart',
 'lib\modules\anime\anime_player_view.dart',
 'test\yh_057_p8f_test.dart'
)
Sync-Overlay $files
$rc = Run-Tests @('test\yh_057_p8f_test.dart','test\yh_057_qa2_test.dart','test\yh_057_qa3_test.dart','test\yh_057_p7f_test.dart','test\yh_057_p3_test.dart','test\yh_054_test.dart')
Push-Location $B
Write-Host '### ANALYZE'
& flutter.bat analyze --no-pub @files 2>&1 | ForEach-Object { "$_" }
Write-Host "### ANALYZE EXIT $LASTEXITCODE"
Pop-Location
