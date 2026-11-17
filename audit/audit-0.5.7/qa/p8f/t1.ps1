. "D:\Claude A.I\jobs\q057_lib.ps1"
Sync-Overlay @(
 'lib\utils\image_load_timeout.dart',
 'lib\modules\manga\reader\subsampling_scale_image_view\src\ffi_image_decoder.dart',
 'lib\modules\manga\reader\subsampling_scale_image_view\src\subsampling_scale_image_view.dart',
 'lib\modules\manga\reader\subsampling_scale_image_view\src\min_subsampling_image_view.dart',
 'lib\modules\manga\reader\widgets\reader_page_content.dart',
 'test\yh_057_p8f_test.dart'
)
Push-Location $B
Write-Host '### ANALYZE'
& flutter.bat analyze --no-pub lib\utils\image_load_timeout.dart lib\modules\manga\reader\subsampling_scale_image_view\src\ffi_image_decoder.dart lib\modules\manga\reader\subsampling_scale_image_view\src\subsampling_scale_image_view.dart lib\modules\manga\reader\subsampling_scale_image_view\src\min_subsampling_image_view.dart lib\modules\manga\reader\widgets\reader_page_content.dart test\yh_057_p8f_test.dart 2>&1 | ForEach-Object { "$_" }
Write-Host "### ANALYZE EXIT $LASTEXITCODE"
Pop-Location
Run-Tests @('test\yh_057_p8f_test.dart','test\yh_057_qa2_test.dart','test\yh_057_qa3_test.dart','test\yh_057_p7f_test.dart')
