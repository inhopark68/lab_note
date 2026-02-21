from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlmodel import Session, select
from app.db.session import get_session
from app.core.security import decode_token, hash_password
from app.core.config import settings
from app.models.user import User

bearer = HTTPBearer(auto_error=False)

def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(bearer),
    session: Session = Depends(get_session),
) -> User:
    # ✅ DEV: 로그인 완전 우회
    if settings.dev_bypass_auth:
        dev_email = "dev@local"
        user = session.exec(select(User).where(User.email == dev_email)).first()
        if not user:
            user = User(email=dev_email, password_hash=hash_password("dev"), name="DEV")
            session.add(user)
            session.commit()
            session.refresh(user)
        return user

    # 일반 모드(로그인 필요)
    if not creds:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")
    payload = decode_token(creds.credentials)
    if not payload or "sub" not in payload:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    user_email = payload["sub"]
    user = session.exec(select(User).where(User.email == user_email)).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user
