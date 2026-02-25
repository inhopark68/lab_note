from fastapi import APIRouter, UploadFile, File, Form, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
import os, shutil

from ..database import SessionLocal
from ..models.sop import SOP

router = APIRouter(prefix="/api/sops", tags=["SOP"])

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

STORAGE_ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "..", "storage", "sop")
STORAGE_ROOT = os.path.abspath(STORAGE_ROOT)

@router.get("")
def list_sops(db: Session = Depends(get_db)):
    rows = db.query(SOP).order_by(SOP.id.desc()).all()
    return [
        {
            "id": r.id,
            "code": r.code,
            "title": r.title,
            "category": r.category,
            "version": r.version,
            "original_filename": r.original_filename,
            "mime_type": r.mime_type,
            "size_bytes": r.size_bytes,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in rows
    ]

@router.post("/upload")
async def upload_sop(
    title: str = Form(...),
    category: str = Form(""),
    version: str = Form("1.0"),
    code: str | None = Form(None),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    os.makedirs(STORAGE_ROOT, exist_ok=True)

    safe_code = (code or title).replace("/", "_").replace("\\", "_").strip()
    safe_ver = (version or "1.0").replace("/", "_").replace("\\", "_").strip()
    save_dir = os.path.join(STORAGE_ROOT, safe_code, safe_ver)
    os.makedirs(save_dir, exist_ok=True)

    file_path = os.path.join(save_dir, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    st = os.stat(file_path)
    row = SOP(
        code=code,
        title=title,
        category=category,
        version=version,
        file_path=file_path,
        original_filename=file.filename,
        mime_type=file.content_type,
        size_bytes=st.st_size,
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    return {
        "id": row.id,
        "title": row.title,
        "category": row.category,
        "version": row.version,
        "original_filename": row.original_filename,
    }

@router.get("/{sop_id}/download")
def download_sop(sop_id: int, db: Session = Depends(get_db)):
    row = db.query(SOP).filter(SOP.id == sop_id).first()
    if not row:
        raise HTTPException(status_code=404, detail="SOP not found")
    if not os.path.exists(row.file_path):
        raise HTTPException(status_code=404, detail="File missing on server")
    return FileResponse(row.file_path, filename=row.original_filename, media_type=row.mime_type or "application/octet-stream")
