# SOP 업로드 시스템이 실제로 끝까지(업로드→저장→DB기록→목록→다운로드) 동작하는지 점검 체크리스트

> 대상: **Lab MVP (Flutter Web + FastAPI/Uvicorn)**  
> 목표: **SOP 업로드가 “끝까지” 실제로 동작**하는지 빠르게 검증

---

## 1) 백엔드 실행 전 점검

- [ ] `backend/app/main.py`에 `app.include_router(sops_router)`가 있음
- [ ] `backend/app/routers/sops.py`가 존재하고 `APIRouter(prefix="/api/sops", ...)`로 선언됨
- [ ] `backend/app/database.py`에서 SQLite `engine`/`SessionLocal`/`Base`가 정상 생성됨
- [ ] `backend/app/models.py`에 SOP 테이블 모델이 있고 `Base.metadata.create_all()` 대상에 포함됨

---

## 2) 백엔드 실행 체크

### 실행 명령
- [ ] 아래 명령이 에러 없이 실행됨

```bash
uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
```

### 로그 확인
- [ ] `Uvicorn running on http://127.0.0.1:8000`가 보임
- [ ] `ImportError` / `ModuleNotFoundError`가 없음
- [ ] DB 관련 에러(권한/경로)가 없음

---

## 3) Swagger(OpenAPI) 확인

- [ ] 브라우저에서 접속됨: `http://127.0.0.1:8000/docs`
- [ ] 아래 API가 보임
  - [ ] `GET /api/sops`
  - [ ] `POST /api/sops/upload`
  - [ ] `GET /api/sops/{id}/download`

---

## 4) 업로드 API 단독 테스트 (Swagger에서)

### `POST /api/sops/upload`
- [ ] `title`, `category`, `version` 등 Form 필드 입력 가능
- [ ] 파일 선택(UploadFile) 가능 (MVP는 PDF 권장)
- [ ] Execute 후 **200 응답**(또는 성공 응답) 확인
- [ ] 응답에 `id` 또는 `file_path` 등 저장 결과가 포함됨

### 파일 저장 확인
- [ ] 서버에 파일이 실제 생성됨  
  - 예: `backend/storage/sop/...` 또는 설정된 저장 경로

### DB 기록 확인(선택)
- [ ] SQLite 파일이 생성/갱신됨 (예: `*.db`)
- [ ] `sop_documents` 테이블에 row가 추가됨

---

## 5) 목록 API 확인

### `GET /api/sops`
- [ ] 업로드한 SOP가 리스트에 포함됨
- [ ] 최신 업로드가 반영됨(서버 재시작 없이도)

---

## 6) 다운로드 확인

### `GET /api/sops/{id}/download`
- [ ] 업로드한 SOP의 `id`로 호출 시 파일이 다운로드됨
- [ ] `Content-Type`이 적절히 설정됨 (PDF면 `application/pdf`)
- [ ] 파일명이 `Content-Disposition`으로 적절히 설정됨(선택)

---

## 7) 프론트(Flutter Web) 연동 점검

### Flutter 실행
- [ ] 프론트가 에러 없이 빌드됨
- [ ] SOP 메뉴 진입 시 목록 화면이 정상 표시됨(데이터가 없어도 화면은 떠야 함)

### 업로드 버튼/기능
- [ ] SOP 화면에 **업로드 버튼**이 보임
- [ ] 파일 선택 창이 열림
- [ ] 업로드 후 목록이 자동 갱신되거나 새 항목이 보임

---

## 8) 흔한 문제와 즉시 해결

### A. 브라우저가 2개 뜸
- 원인: `flutter run -d chrome`(Flutter가 Chrome 자동 오픈) + launch.bat에서 Chrome을 또 오픈
- 해결: 둘 중 하나만 사용
  - 방식 1: Chrome은 Flutter에게 맡기기 (`flutter run -d chrome`만)
  - 방식 2: Flutter는 `-d web-server`, Chrome은 URL로 1회만 오픈

### B. CORS 에러(웹에서 업로드 실패)
- 원인: FastAPI에 CORS 미들웨어 미설정
- 해결: `CORSMiddleware` 추가 후 프론트 도메인/포트 허용

### C. `404 /api/sops`
- 원인: router prefix(`/api/sops`) 또는 `include_router()` 연결 불일치
- 해결: `routers/sops.py`의 prefix와 `main.py`의 include를 재확인

### D. 파일은 저장되는데 목록에 안 뜸
- 원인: 업로드 처리에서 DB insert 누락(파일만 저장)
- 해결: 업로드 핸들러에서 모델 생성 및 DB commit 수행

---

## 9) 최종 통과 기준

- [ ] Swagger 업로드(POST) 성공
- [ ] 서버 저장소에 파일 생성 확인
- [ ] `GET /api/sops`에 항목 노출
- [ ] `GET /api/sops/{id}/download` 다운로드 성공
- [ ] Flutter에서 업로드→목록 갱신까지 확인

---

### 부록: 빠른 “정상 동작” 확인 루틴(5분)
1) `uvicorn ...` 실행  
2) `/docs` 접속  
3) `POST /api/sops/upload`로 PDF 1개 업로드  
4) `GET /api/sops`에서 업로드 항목 확인  
5) `GET /api/sops/{id}/download` 다운로드 확인  
6) Flutter에서 동일 SOP가 목록에 보이는지 확인
