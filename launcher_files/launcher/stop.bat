@echo off
setlocal
REM launcher\stop.bat
REM Simple wrapper for PowerShell script.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop.ps1"
endlocal
