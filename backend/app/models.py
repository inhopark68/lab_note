from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from .database import Base

class SopDocument(Base):
    __tablename__ = "sop_documents"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, index=True, nullable=True)  # SOP-001 같은 문서군 식별자(선택)
    title = Column(String, nullable=False)
    category = Column(String, nullable=True)
    version = Column(String, nullable=True)
    file_path = Column(String, nullable=False)
    original_filename = Column(String, nullable=False)
    mime_type = Column(String, nullable=True)
    size_bytes = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
