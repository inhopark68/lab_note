from typing import Optional
from sqlmodel import SQLModel, Field
from app.models.common import TimestampMixin

class Attachment(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    entity_type: str = Field(index=True)  # equipment/facility/reagent/record/sop/template
    entity_id: int = Field(index=True)
    filename: str
    content_type: str = Field(default="")
    stored_path: str
    note: str = Field(default="")
