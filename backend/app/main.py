from fastapi import FastAPI
from .database import Base, engine
from .routers.sops import router as sops_router

app = FastAPI(title="Lab MVP API")

Base.metadata.create_all(bind=engine)

app.include_router(sops_router)

# run:
# uvicorn backend.app.main:app --reload --host 127.0.0.1 --port 8000
