# Lab MVP SOP 업로드 시스템 - 최종 패키지

이 패키지는 Flutter(frontend)와 FastAPI(backend)에 SOP 업로드 기능을 추가하기 위한 **필수 파일 + 업데이트된 파일**을 포함합니다.

## 포함 파일
### Frontend (Flutter)
- `lib/api/api_client.dart` : Multipart 업로드 메서드(`postMultipart`) 추가
- `lib/api/entities_api.dart` : `uploadSop()`, `sopDownloadUrl()` 추가
- `lib/pages/list_page.dart` : SOP 화면에 `업로드` 버튼 + Web 파일 선택/업로드 다이얼로그 추가
- `lib/pages/shell.dart`, `lib/main.dart` : 메뉴/라우팅 유지(기존 연결 복구 버전)
- `lib/template_screen_with_resized_panels.dart` : (기존 유지)

### Backend (FastAPI) - 신규
- `backend/app/database.py`
- `backend/app/models.py`
- `backend/app/routers/sops.py`
- `backend/app/main.py` (샘플)

> **주의:** backend는 프로젝트 기존 구조에 맞게 `routers/sops.py`만 붙여 넣고 `include_router`를 추가하는 방식으로 적용하는 것을 권장합니다.

## 적용 방법(요약)
1. frontend 폴더의 `lib/` 하위 파일을 동일 경로에 덮어쓰기
2. backend에 `routers/sops.py` 추가 후 `main.py`에 `include_router` 등록
3. 백엔드 업로드 디렉토리 생성: `backend/storage/sop/`
4. 실행:
   - backend: `uvicorn main:app --reload --host 127.0.0.1 --port 8000`
   - frontend: `flutter run -d chrome`

## API 기본 주소
`lib/pages/shell.dart`의 `apiBaseUrl` 기본값:
- `http://127.0.0.1:8000/api`

환경에 맞게 수정하세요.
