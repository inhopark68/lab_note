from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from sqlmodel import Session
from pathlib import Path
import uuid
from app.core.config import settings
from app.db.session import get_session
from app.models.attachment import Attachment
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/")
async def upload_file(
    entity_type: str,
    entity_id: int,
    note: str = "",
    file: UploadFile = File(...),
    session: Session = Depends(get_session),
    _=Depends(get_current_user),
):
    if entity_type not in {"equipment","facility","reagent","record","sop","template"}:
        raise HTTPException(400, "Invalid entity_type")
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(parents=True, exist_ok=True)

    ext = Path(file.filename).suffix
    stored_name = f"{entity_type}_{entity_id}_{uuid.uuid4().hex}{ext}"
    stored_path = upload_dir / stored_name

    content = await file.read()
    stored_path.write_bytes(content)

    att = Attachment(
        entity_type=entity_type,
        entity_id=entity_id,
        filename=file.filename,
        content_type=file.content_type or "",
        stored_path=str(stored_path),
        note=note,
    )
    session.add(att)
    session.commit()
    session.refresh(att)

    return {
        "id": att.id,
        "filename": att.filename,
        "url": f"/uploads/{stored_name}",
        "note": att.note,
    }

@router.get("/{entity_type}/{entity_id}")
def list_attachments(
    entity_type: str,
    entity_id: int,
    session: Session = Depends(get_session),
    _=Depends(get_current_user),
):
    from sqlmodel import select
    rows = session.exec(select(Attachment).where(Attachment.entity_type==entity_type, Attachment.entity_id==entity_id)).all()
    out = []
    for r in rows:
        stored_name = Path(r.stored_path).name
        out.append({"id": r.id, "filename": r.filename, "url": f"/uploads/{stored_name}", "note": r.note})
    return out
