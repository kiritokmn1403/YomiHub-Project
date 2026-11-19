@echo off
title YomiHub - chay cac tac vu
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\runner\run_jobs.ps1"
