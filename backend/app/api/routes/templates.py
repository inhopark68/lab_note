from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from app.db.session import get_session
from app.models.experiment_template import ExperimentTemplate

router = APIRouter()


@router.get("/", response_model=list[ExperimentTemplate])
def list_templates(session: Session = Depends(get_session)):
    return session.exec(select(ExperimentTemplate).order_by(ExperimentTemplate.id.desc())).all()


@router.get("/{template_id}", response_model=ExperimentTemplate)
def get_template(template_id: int, session: Session = Depends(get_session)):
    obj = session.get(ExperimentTemplate, template_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Template not found")
    return obj


@router.post("/", response_model=ExperimentTemplate)
def create_template(payload: ExperimentTemplate, session: Session = Depends(get_session)):
    # Ensure id not forced
    data = payload.model_dump(exclude={"id"})
    obj = ExperimentTemplate(**data)
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


@router.put("/{template_id}", response_model=ExperimentTemplate)
def update_template(template_id: int, payload: ExperimentTemplate, session: Session = Depends(get_session)):
    obj = session.get(ExperimentTemplate, template_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Template not found")
    data = payload.model_dump(exclude={"id"})
    for k, v in data.items():
        setattr(obj, k, v)
    session.add(obj)
    session.commit()
    session.refresh(obj)
    return obj


@router.delete("/{template_id}")
def delete_template(template_id: int, session: Session = Depends(get_session)):
    obj = session.get(ExperimentTemplate, template_id)
    if not obj:
        raise HTTPException(status_code=404, detail="Template not found")
    session.delete(obj)
    session.commit()
    return {"ok": True}
