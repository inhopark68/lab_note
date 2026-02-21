from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.api.router import api_router
from app.db.session import init_db
from app.core.config import settings

def create_app() -> FastAPI:
    app = FastAPI(title="Lab MVP API", version="0.1.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],  # MVP: tighten in prod
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    init_db()

    # serve uploaded files
    app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

    app.include_router(api_router, prefix="/api")

    return app

app = create_app()
