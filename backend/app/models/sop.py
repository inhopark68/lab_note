from typing import Optional
from sqlmodel import SQLModel, Field
from .common import TimestampMixin

class SOP(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(index=True)
    version: str = Field(default="v1.0")
    domain: str = Field(default="공용", index=True)
    summary: str = Field(default="")
    body_markdown: str = Field(default="")
    tags: str = Field(default="")
