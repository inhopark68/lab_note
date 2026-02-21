from typing import Optional
from sqlmodel import SQLModel, Field
from app.models.common import TimestampMixin

class Equipment(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    model_vendor: str = Field(default="")
    asset_no: str = Field(default="", index=True)
    status: str = Field(default="사용중", index=True)
    domain: str = Field(default="공용", index=True)  # e.g., 세포/분자/단백질/이미징/공용
    hazards: str = Field(default="")  # comma-separated
    facility_id: Optional[int] = Field(default=None, foreign_key="facility.id", index=True)
    location_detail: str = Field(default="")
    owner: str = Field(default="")
    training_required: bool = Field(default=False)
    usage_frequency: str = Field(default="비정기")
    key_parameters: str = Field(default="")
    precheck_summary: str = Field(default="")
    postclean_summary: str = Field(default="")
    maintenance_cycle: str = Field(default="분기")
    last_maintenance_date: str = Field(default="")
    next_maintenance_date: str = Field(default="")
    manual_url: str = Field(default="")
    tags: str = Field(default="")
    body_markdown: str = Field(default="")  # 카드 본문(템플릿 기반)
