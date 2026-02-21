from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.db.session import get_session
from app.models.equipment import Equipment
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=list[Equipment])
def list_equipment(session: Session = Depends(get_session), _=Depends(get_current_user)):
    return session.exec(select(Equipment).order_by(Equipment.name)).all()

@router.post("/", response_model=Equipment)
def create_equipment(item: Equipment, session: Session = Depends(get_session), _=Depends(get_current_user)):
    item.id = None
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

@router.get("/{equipment_id}", response_model=Equipment)
def get_equipment(equipment_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Equipment, equipment_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.put("/{equipment_id}", response_model=Equipment)
def update_equipment(equipment_id: int, item: Equipment, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Equipment, equipment_id)
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

@router.delete("/{equipment_id}")
def delete_equipment(equipment_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Equipment, equipment_id)
    if not obj:
        raise HTTPException(404, "Not found")
    session.delete(obj)
    session.commit()
    return {"ok": True}
