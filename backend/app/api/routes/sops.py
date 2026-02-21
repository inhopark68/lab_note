from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.db.session import get_session
from app.models.sop import SOP
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=list[SOP])
def list_sops(session: Session = Depends(get_session), _=Depends(get_current_user)):
    return session.exec(select(SOP).order_by(SOP.title)).all()

@router.post("/", response_model=SOP)
def create_sop(item: SOP, session: Session = Depends(get_session), _=Depends(get_current_user)):
    item.id = None
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

@router.get("/{sop_id}", response_model=SOP)
def get_sop(sop_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(SOP, sop_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.put("/{sop_id}", response_model=SOP)
def update_sop(sop_id: int, item: SOP, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(SOP, sop_id)
    if not obj:
        raise HTTPException(404, "Not found")
    data = item.model_dump(exclude_unset=True)
    for k, v in data.items():
        if k != "id":
            setattr(obj, k, v)
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj

@router.delete("/{sop_id}")
def delete_sop(sop_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(SOP, sop_id)
    if not obj:
        raise HTTPException(404, "Not found")
    session.delete(obj)
    session.commit()
    return {"ok": True}
