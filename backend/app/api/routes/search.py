from fastapi import APIRouter, Depends
from sqlmodel import Session, select, or_
from app.db.session import get_session
from app.models.equipment import Equipment
from app.models.facility import Facility
from app.models.reagent import Reagent
from app.models.experiment_record import ExperimentRecord
from app.api.deps import get_current_user

router = APIRouter()

def like(q: str) -> str:
    return f"%{q}%"

@router.get("/")
def search(q: str, type: str = "all", session: Session = Depends(get_session), _=Depends(get_current_user)):
    q = q.strip()
    if not q:
        return {"equipment": [], "facilities": [], "reagents": [], "records": []}

    results = {}
    if type in ("all","equipment"):
        rows = session.exec(select(Equipment).where(or_(Equipment.name.like(like(q)), Equipment.tags.like(like(q)), Equipment.asset_no.like(like(q))))).all()
        results["equipment"] = rows
    if type in ("all","facilities"):
        rows = session.exec(select(Facility).where(or_(Facility.name.like(like(q)), Facility.tags.like(like(q)), Facility.location.like(like(q))))).all()
        results["facilities"] = rows
    if type in ("all","reagents"):
        rows = session.exec(select(Reagent).where(or_(Reagent.name.like(like(q)), Reagent.tags.like(like(q)), Reagent.cat_no.like(like(q)), Reagent.lot_no.like(like(q))))).all()
        results["reagents"] = rows
    if type in ("all","records"):
        rows = session.exec(select(ExperimentRecord).where(or_(ExperimentRecord.title.like(like(q)), ExperimentRecord.tags.like(like(q)), ExperimentRecord.purpose.like(like(q))))).all()
        results["records"] = rows
    return results
