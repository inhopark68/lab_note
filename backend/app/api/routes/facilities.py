from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select
from app.db.session import get_session
from app.models.facility import Facility
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/", response_model=list[Facility])
def list_facilities(session: Session = Depends(get_session), _=Depends(get_current_user)):
    return session.exec(select(Facility).order_by(Facility.name)).all()

@router.post("/", response_model=Facility)
def create_facility(item: Facility, session: Session = Depends(get_session), _=Depends(get_current_user)):
    item.id = None
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

@router.get("/{facility_id}", response_model=Facility)
def get_facility(facility_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Facility, facility_id)
    if not obj:
        raise HTTPException(404, "Not found")
    return obj

@router.put("/{facility_id}", response_model=Facility)
def update_facility(facility_id: int, item: Facility, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Facility, facility_id)
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

@router.delete("/{facility_id}")
def delete_facility(facility_id: int, session: Session = Depends(get_session), _=Depends(get_current_user)):
    obj = session.get(Facility, facility_id)
    if not obj:
        raise HTTPException(404, "Not found")
    session.delete(obj)
    session.commit()
    return {"ok": True}
