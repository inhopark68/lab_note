from fastapi import APIRouter
from app.api.routes import auth, facilities, equipment, reagents, sops, templates, records, uploads, search

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(facilities.router, prefix="/facilities", tags=["facilities"])
api_router.include_router(equipment.router, prefix="/equipment", tags=["equipment"])
api_router.include_router(reagents.router, prefix="/reagents", tags=["reagents"])
api_router.include_router(sops.router, prefix="/sops", tags=["sops"])
# ✅ 이 두 줄이 없으면 /templates /records 가 404
api_router.include_router(templates.router, prefix="/templates", tags=["templates"])
api_router.include_router(records.router, prefix="/records", tags=["records"])

api_router.include_router(uploads.router, prefix="/uploads", tags=["uploads"])
api_router.include_router(search.router, prefix="/search", tags=["search"])
