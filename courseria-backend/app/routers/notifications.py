from fastapi import APIRouter, HTTPException, Depends, status
from app.database import get_db
from app.dependencies import get_current_user
from typing import List
from pydantic import BaseModel
import datetime

router = APIRouter()

class NotificationBase(BaseModel):
    id: str
    title: str
    body: str
    type: str  # broadcast, transaction, course
    created_at: datetime.datetime

@router.get("/", response_model=List[NotificationBase])
@router.get("", response_model=List[NotificationBase], include_in_schema=False)
async def get_notifications(user=Depends(get_current_user), db=Depends(get_db)):
    """Fetch global and user-specific notifications"""
    try:
        # Fetch notifications: global (user_id is null) or specific to the user
        response = db.table("notifications").select("*").or_(f"user_id.eq.{user['sub']},user_id.is.null").order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        print(f"!!! Notifications Fetch Error: {e}")
        return []
