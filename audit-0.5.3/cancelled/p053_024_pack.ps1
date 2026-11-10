# timeout: 60
$ErrorActionPreference="Continue"; Set-Location "D:\A.I Project\A.I Project - YomiHub Project\YomiHub-Project"
powershell -ExecutionPolicy Bypass -File .\build_053.ps1 -step pack 2>&1 | Select-Object -Last 10
