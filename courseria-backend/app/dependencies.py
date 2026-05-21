from fastapi import Header, HTTPException, Depends
from jose import jwt, JWTError
from app.config import get_settings

settings = get_settings()

def verify_token(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid token type")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        raise HTTPException(status_code=401, detail="Could not validate credentials")

def get_current_user(payload: dict = Depends(verify_token)):
    return payload
