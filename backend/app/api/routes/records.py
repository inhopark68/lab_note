from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select, delete

from app.db.session import get_session
from app.models.experiment_record import ExperimentRecord
from app.models.link_tables import RecordEquipmentLink, RecordReagentLink

router = APIRouter()


@router.get("/", response_model=list[ExperimentRecord])
def list_records(session: Session = Depends(get_session)):
    return session.exec(select(ExperimentRecord).order_by(ExperimentRecord.id.desc())).all()


@router.get("/{record_id}", response_model=ExperimentRecord)
def get_record(record_id: int, session: Session = Depends(get_session)):
    obj = session.get(ExperimentRecord, record_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Record not found")
    return obj


@router.post("/", response_model=ExperimentRecord)
def create_record(payload: ExperimentRecord, session: Session = Depends(get_session)):
    data = payload.model_dump(exclude={"id"})
    obj = ExperimentRecord(**data)
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


@router.put("/{record_id}", response_model=ExperimentRecord)
def update_record(record_id: int, payload: ExperimentRecord, session: Session = Depends(get_session)):
    obj = session.get(ExperimentRecord, record_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Record not found")
    data = payload.model_dump(exclude={"id"})
    for k, v in data.items():
        setattr(obj, k, v)
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


@router.delete("/{record_id}")
def delete_record(record_id: int, session: Session = Depends(get_session)):
    obj = session.get(ExperimentRecord, record_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Record not found")
    session.delete(obj)
    session.commit()
    # also cleanup links
    session.exec(delete(RecordEquipmentLink).where(RecordEquipmentLink.record_id == record_id))
    session.exec(delete(RecordReagentLink).where(RecordReagentLink.record_id == record_id))
    session.commit()
    return {"ok": True}


# ---------- Link helpers used by Flutter ----------

@router.get("/{record_id}/equipment-ids")
def get_equipment_ids(record_id: int, session: Session = Depends(get_session)):
    links = session.exec(select(RecordEquipmentLink).where(RecordEquipmentLink.record_id == record_id)).all()
    return {"ids": [l.equipment_id for l in links]}


@router.get("/{record_id}/reagent-ids")
def get_reagent_ids(record_id: int, session: Session = Depends(get_session)):
    links = session.exec(select(RecordReagentLink).where(RecordReagentLink.record_id == record_id)).all()
    return {"ids": [l.reagent_id for l in links]}


@router.post("/{record_id}/set-equipment")
def set_equipment_ids(record_id: int, payload: dict, session: Session = Depends(get_session)):
    ids = payload.get("ids") or []
    if not isinstance(ids, list):
        raise HTTPException(status_code=400, detail="ids must be a list")
    # clear then insert
    session.exec(delete(RecordEquipmentLink).where(RecordEquipmentLink.record_id == record_id))
    session.commit()
    for eid in ids:
        session.add(RecordEquipmentLink(record_id=record_id, equipment_id=int(eid)))
    session.commit()
    return {"ok": True, "count": len(ids)}


@router.post("/{record_id}/set-reagents")
def set_reagent_ids(record_id: int, payload: dict, session: Session = Depends(get_session)):
    ids = payload.get("ids") or []
    if not isinstance(ids, list):
        raise HTTPException(status_code=400, detail="ids must be a list")
    session.exec(delete(RecordReagentLink).where(RecordReagentLink.record_id == record_id))
    session.commit()
    for rid in ids:
        session.add(RecordReagentLink(record_id=record_id, reagent_id=int(rid)))
    session.commit()
    return {"ok": True, "count": len(ids)}
