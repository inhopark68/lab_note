# launcher (v2)

## 왜 "화면이 떴다가 사라짐"이 발생했나요?
- launch.bat로 실행했을 때 내부 에러가 나면 창이 바로 닫히면서 그렇게 보일 수 있습니다.
- v2는 flutter clean/pub get도 logs에 남기고, bat는 pause로 창을 유지합니다.

## 사용
```powershell
cd D:\coding\lab_note
.\launcher\launch.ps1
```

종료:
```powershell
.\launcher\stop.ps1
```

## 로그 확인
- backend: launcher\logs\backend-*.err.log
- frontend: launcher\logs\frontend-*.err.log
- flutter 단계: launcher\logs\flutter-clean-*.err.log, flutter-pub-get-*.err.log
