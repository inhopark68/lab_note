# launcher 사용법 (Windows 11)

## 구성
- launcher\launch.ps1  : backend + frontend 실행, PID 저장, 로그 저장
- launcher\stop.ps1    : PID로 정확히 종료(프로세스 트리까지)
- launcher\launch.bat  : PowerShell 실행 래퍼(옵션)
- launcher\stop.bat    : PowerShell 실행 래퍼(옵션)
- launcher\pids\        : PID 파일 저장 위치
- launcher\logs\        : 로그 저장 위치

## 사용
PowerShell에서 프로젝트 루트(launcher 폴더가 있는 위치)로 이동 후:

```powershell
cd D:\coding\lab_note
.\launcher\launch.ps1
```

종료:

```powershell
.\launcher\stop.ps1
```

## 경로/포트 변경
`launcher\launch.ps1` 상단 CONFIG 섹션의 아래 값만 수정하세요.
- $BackendDir, $FrontendDir
- $BackendPort, $BackendApp
- $FlutterDevice

## 참고
- backend는 `.venv\Scripts\python.exe`로 실행하므로 "activate"가 필요 없습니다.
- uvicorn --reload는 자식 프로세스를 만들기 때문에 stop.ps1은 taskkill /T /F로 트리 전체를 종료합니다.
