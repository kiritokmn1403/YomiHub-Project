@echo off
rem YomiHub 0.6.7 - nhap dup tep nay, bam "Yes" o hop UAC de cai goi TV + Samsung Certificate cho Tizen Studio.
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0cai_goi_samsung_tv.ps1""'"
