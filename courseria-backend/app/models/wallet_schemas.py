from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class TransactionStatus(str, Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"

class WalletBase(BaseModel):
    user_id: str
    balance: int = 0
    updated_at: datetime

class WalletTransactionBase(BaseModel):
    id: str
    user_id: str
    transaction_id: str
    amount: float
    status: str  # pending, approved, rejected
    payment_method: str
    receipt_screenshot_url: Optional[str] = None
    note: Optional[str] = None
    created_at: datetime
    processed_at: Optional[datetime] = None

class DepositReceiptRequest(BaseModel):
    transaction_id: str
    amount: float
    payment_method: str # شام كاش, سيرياتيل كاش, نقداً في مركز معاذ الشيخ
    receipt_screenshot_url: Optional[str] = None
    note: Optional[str] = None

class WalletRechargeCreate(BaseModel):
    transaction_id: str
    amount: float
    note: Optional[str] = None

class WalletRechargeRequest(BaseModel):
    amount: float
    payment_method: str
    transaction_id: str
    receipt_screenshot_url: Optional[str] = None
    note: Optional[str] = None

class WalletRechargeResponse(BaseModel):
    id: str
    status: str
    message: str

class WalletBalanceResponse(BaseModel):
    balance: int
