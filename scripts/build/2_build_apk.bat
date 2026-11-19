@echo off
title YomiHub - Buoc 2: build APK
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_apk.ps1"
echo.
echo Xong. File APK nam trong thu muc output.
timeout /t 60
