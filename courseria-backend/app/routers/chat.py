from fastapi import APIRouter, HTTPException, Depends, status, Body
from app.dependencies import get_current_user, get_supabase_client
from typing import List, Optional
import datetime

router = APIRouter()

@router.get("/rooms")
async def get_chat_rooms(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب غرف الدردشة الخاصة بالمستخدم"""
    try:
        # User is part of a room if they are either 'student_id' or 'teacher_id'
        # or if the room is public
        response = db.table("chat_rooms").select("*").or_(f"student_id.eq.{user['user_id']},is_public.eq.true").execute()
        return response.data
    except Exception as e:
        print(f"Fetch Chat Rooms Error: {e}")
        # Return empty list if table or query fails
        return []

@router.get("/rooms/{room_id}/messages", response_model=List[dict])
async def get_messages(
    room_id: str, 
    last_msg_id: Optional[str] = None,
    limit: int = 50,
    db=Depends(get_supabase_client)
):
    """جلب الرسائل من غرفة معينة"""
    try:
        query = db.table("chat_messages").select("*, users(full_name, avatar_url)").eq("room_id", room_id).order("created_at", desc=True).limit(limit)
        if last_msg_id:
            # في الواقع نحتاج للمقارنة بالزمن أو المعرف الترتيبي
            pass
        response = query.execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في جلب الرسائل")

@router.post("/rooms/{room_id}/messages")
async def send_message(
    room_id: str,
    content: str = Body(...),
    msg_type: str = Body("text"), # text, image, pdf
    file_url: Optional[str] = Body(None),
    user=Depends(get_current_user),
    db=Depends(get_supabase_client)
):
    """إرسال رسالة إلى الغرفة"""
    try:
        msg_data = {
            "room_id": room_id,
            "user_id": user["user_id"],
            "content": content,
            "msg_type": msg_type,
            "file_url": file_url,
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        response = db.table("chat_messages").insert(msg_data).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في إرسال الرسالة")

@router.post("/rooms/{room_id}/typing")
async def set_typing(room_id: str, is_typing: bool = Body(..., embed=True), user=Depends(get_current_user)):
    """إرسال مؤشر الكتابة (يتم التعامل معه غالباً عبر Realtime مباشرة)"""
    return {"status": "success"}

@router.post("/messages/{msg_id}/read")
async def mark_as_read(msg_id: str, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """إرسال إيصال قراءة"""
    try:
        db.table("chat_reads").upsert({
            "message_id": msg_id,
            "user_id": user["user_id"],
            "read_at": datetime.datetime.utcnow().isoformat()
        }).execute()
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل تحديث حالة القراءة")
