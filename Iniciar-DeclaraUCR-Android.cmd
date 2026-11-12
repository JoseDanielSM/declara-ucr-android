@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0horario_ucr-main\Start-Android.ps1"
if errorlevel 1 pause
