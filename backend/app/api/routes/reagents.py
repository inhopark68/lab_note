from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.db.session import get_session
from app.models.reagent import Reagent
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=list[Reagent])
def list_reagents(session: Session = Depends(get_session), _=Depends(get_current_user)):
    return session.exec(select(Reagent).order_by(Reagent.name)).all()

@router.post("/", response_model=Reagent)
def create_reagent(item: Reagent, session: Session = Depends(get_session), _=Depends(get_current_user)):
    item.id = None
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

@router.get("/{reagent_id}", response_model=Reagent)
def get_reagent(reagent_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Reagent, reagent_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.put("/{reagent_id}", response_model=Reagent)
def update_reagent(reagent_id: int, item: Reagent, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Reagent, reagent_id)
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

@router.delete("/{reagent_id}")
def delete_reagent(reagent_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Reagent, reagent_id)
    if not obj:
        raise HTTPException(404, "Not found")
    session.delete(obj)
    session.commit()
    return {"ok": True}
