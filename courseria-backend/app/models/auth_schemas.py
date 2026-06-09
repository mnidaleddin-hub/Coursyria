from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class OTPRequest(BaseModel):
    contact: str = Field(..., description="International phone number")
    channel: Optional[str] = Field("whatsapp", description="whatsapp or telegram")
    type: str = Field("login", description="login or register")

class LoginRequest(BaseModel):
    identifier: str # Email or Phone
    password: Optional[str] = None
    device_id: Optional[str] = None

class RegisterRequest(BaseModel):
    full_name: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    password: str
    device_id: Optional[str] = None
    channel: Optional[str] = "email"
    referral_code: Optional[str] = None

    class Config:
        extra = "ignore" # Allow extra fields without crashing
        from_attributes = True # Support for ORM models if needed

class OTPVerify(BaseModel):
    contact: str
    otp: str
    device_id: Optional[str] = None
    full_name: Optional[str] = None
    password: Optional[str] = None
    channel: Optional[str] = "whatsapp"
    referral_code: Optional[str] = None

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
