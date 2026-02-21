from pydantic import BaseModel
from pathlib import Path

class Settings(BaseModel):
    app_name: str = "Lab MVP API"
    sqlite_path: str = str(Path(__file__).resolve().parents[2] / "data" / "app.db")
    upload_dir: str = str(Path(__file__).resolve().parents[2] / "uploads")
    jwt_secret: str = "CHANGE_ME_IN_PROD"
    jwt_algorithm: str = "HS256"
    jwt_exp_minutes: int = 60 * 24  # 24h

    dev_bypass_auth: bool = True   # ✅ 추가 (개발 중 로그인 패스)


settings = Settings()
