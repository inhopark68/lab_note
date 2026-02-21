# Lab MVP (FastAPI + SQLite) Backend

## Run (dev)
```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

- Swagger UI: http://localhost:8000/docs
- Files served: http://localhost:8000/uploads/<filename>

## Notes
- SQLite DB file: `backend/data/app.db` (auto-created)
- Default upload dir: `backend/uploads/`
