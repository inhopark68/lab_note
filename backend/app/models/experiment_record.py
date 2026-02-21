from typing import Optional
from sqlmodel import SQLModel, Field
from app.models.common import TimestampMixin

class ExperimentRecord(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(index=True)
    date: str = Field(default="")
    performer: str = Field(default="")
    project: str = Field(default="")
    experiment_type: str = Field(default="기타", index=True)
    purpose: str = Field(default="")
    status: str = Field(default="완료", index=True)
    sample_summary: str = Field(default="")
    key_parameters: str = Field(default="")
    method_markdown: str = Field(default="")
    results_summary: str = Field(default="")
    conclusion: str = Field(default="")
    issues_deviation: str = Field(default="")
    followup_recommendations: str = Field(default="")
    raw_data_url: str = Field(default="")
    tags: str = Field(default="")
    sop_id: Optional[int] = Field(default=None, foreign_key="sop.id", index=True)
    template_id: Optional[int] = Field(default=None, foreign_key="experimenttemplate.id", index=True)
