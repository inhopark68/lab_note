from typing import Optional
from sqlmodel import SQLModel, Field
from app.models.common import TimestampMixin

class ExperimentTemplate(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(index=True)
    experiment_type: str = Field(default="기타", index=True)
    summary: str = Field(default="")
    body_markdown: str = Field(default="")
    tags: str = Field(default="")
