from datetime import datetime, timezone
from typing import Optional
from sqlmodel import SQLModel, Field

def utcnow():
    return datetime.now(timezone.utc)

class TimestampMixin(SQLModel):
    created_at: datetime = Field(default_factory=utcnow, index=True)
    updated_at: datetime = Field(default_factory=utcnow, index=True)
