from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class OTPRequest(BaseModel):
    contact: str = Field(..., description="Syrian phone number")
    channel: str = Field("whatsapp", description="whatsapp or telegram")

class OTPVerify(BaseModel):
    contact: str
    otp: str
    device_id: Optional[str] = None

class UserBase(BaseModel):
    id: str
    phone_number: Optional[str] = None
    email: Optional[str] = None
    role: str = "student"
    created_at: datetime

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserBase
