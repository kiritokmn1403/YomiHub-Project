& "D:\yh\build\mangayomi\android\gradlew.bat" --stop
Start-Sleep 2
$dirs = @(
  "D:\yh\build\mangayomi\build\app\intermediates\incremental",
  "D:\yh\build\mangayomi\build\app\intermediates\merged_res",
  "D:\yh\build\mangayomi\build\app\intermediates\merged_res_blame_folder",
  "D:\yh\build\mangayomi\build\app\intermediates\merged-not-compiled-resources",
  "D:\yh\build\mangayomi\build\app\intermediates\packaged_res",
  "D:\yh\build\mangayomi\build\app\intermediates\linked_resources_proto_format",
  "D:\yh\build\mangayomi\build\app\intermediates\shrunk_resources_binary_format",
  "D:\yh\build\mangayomi\build\app\intermediates\shrunk_resources_proto_format",
  "D:\yh\build\mangayomi\build\app\intermediates\merged_manifest",
  "D:\yh\build\mangayomi\build\app\intermediates\merged_manifests"
)
foreach ($d in $dirs) {
  if (Test-Path $d) {
    Remove-Item $d -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Removed $d"
  }
}
Write-Host "Clean finished."
