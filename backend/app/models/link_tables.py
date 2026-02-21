from typing import Optional
from sqlmodel import SQLModel, Field

class RecordEquipmentLink(SQLModel, table=True):
    record_id: Optional[int] = Field(default=None, foreign_key="experimentrecord.id", primary_key=True)
    equipment_id: Optional[int] = Field(default=None, foreign_key="equipment.id", primary_key=True)

class RecordReagentLink(SQLModel, table=True):
    record_id: Optional[int] = Field(default=None, foreign_key="experimentrecord.id", primary_key=True)
    reagent_id: Optional[int] = Field(default=None, foreign_key="reagent.id", primary_key=True)
