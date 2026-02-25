@REM @echo off
@REM powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch.ps1"
@REM echo.
@REM echo (Press any key to close)
@REM pause >nul

@REM @echo off
@REM powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch.ps1"
@REM exit


@echo off
setlocal

REM (예) 백엔드 실행
start "Backend" cmd /c "cd /d D:\coding\lab_note\backend && .venv\Scripts\activate && uvicorn main:app --reload --host 127.0.0.1 --port 8000"

REM ✅ 프론트엔드는 Flutter가 Chrome을 직접 열게 둠 (브라우저 1개)
start "Flutter" cmd /c "cd /d D:\coding\lab_note\frontend && flutter run -d chrome"

endlocal