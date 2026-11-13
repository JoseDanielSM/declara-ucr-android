@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0horario_ucr-main\Prepare-Local.ps1" %*
if errorlevel 1 pause
