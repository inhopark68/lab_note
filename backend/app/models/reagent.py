from typing import Optional
from sqlmodel import SQLModel, Field
from app.models.common import TimestampMixin

class Reagent(TimestampMixin, SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str = Field(index=True)
    category: str = Field(default="기타", index=True)
    vendor: str = Field(default="")
    cat_no: str = Field(default="", index=True)
    lot_no: str = Field(default="", index=True)
    concentration_form: str = Field(default="")
    storage_temp: str = Field(default="RT", index=True)
    light_sensitive: bool = Field(default=False)
    open_date: str = Field(default="")
    expiry_date: str = Field(default="")
    stock_status: str = Field(default="보통", index=True)
    min_stock: int = Field(default=0)
    qty_est: int = Field(default=0)
    storage_location: str = Field(default="")
    hazards: str = Field(default="")
    ppe: str = Field(default="")
    sds_url: str = Field(default="")
    prep_dilution: str = Field(default="")
    usage_summary: str = Field(default="")
    cautions: str = Field(default="")
    tags: str = Field(default="")
    body_markdown: str = Field(default="")
