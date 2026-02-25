@echo off
setlocal
REM launcher\launch.bat
REM Simple wrapper for PowerShell script.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch.ps1"
endlocal
