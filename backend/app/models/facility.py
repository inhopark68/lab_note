from typing import Optional
from sqlmodel import SQLModel, Field
from app.models.common import TimestampMixin

class Facility(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    facility_type: str = Field(default="기타", index=True)
    location: str = Field(default="")
    access_conditions: str = Field(default="")  # comma-separated
    bsl_level: str = Field(default="해당없음", index=True)
    hours: str = Field(default="")
    manager: str = Field(default="")
    emergency_contact: str = Field(default="")
    rules_summary: str = Field(default="")
    incident_response: str = Field(default="")
    waste_flow: str = Field(default="")
    tags: str = Field(default="")  # comma-separated
