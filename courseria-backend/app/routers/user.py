from fastapi import APIRouter, HTTPException, Depends, status, Body, UploadFile, File
from app.dependencies import get_current_user, get_supabase_client
from typing import List, Optional
import datetime

router = APIRouter()

@router.get("/me")
async def get_my_profile(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب بيانات المستخدم الحالي"""
    try:
        response = db.table("users").select("*").eq("id", user["user_id"]).single().execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في جلب البيانات")

@router.put("/me")
async def update_profile(
    updates: dict = Body(...),
    user=Depends(get_current_user),
    db=Depends(get_supabase_client)
):
    """تحديث الملف الشخصي"""
    try:
        # منع تحديث الحقول الحساسة برمجياً
        allowed_fields = ["full_name", "phone_number", "avatar_url", "bio", "city", "specialization"]
        filtered_updates = {k: v for k, v in updates.items() if k in allowed_fields}
        
        response = db.table("users").update(filtered_updates).eq("id", user["user_id"]).execute()
        return response.data[0]
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في تحديث البيانات")

@router.get("/stats")
async def get_user_stats(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب إحصائيات الطالب (النقاط، التقدم، الإنجازات)"""
    try:
        # 1. Points
        points_res = db.table("user_points").select("points").eq("user_id", user["user_id"]).maybe_single().execute()
        points = points_res.data["points"] if points_res.data else 0
        
        # 2. Courses Count
        courses_res = db.table("user_courses").select("id", count="exact").eq("user_id", user["user_id"]).execute()
        courses_count = courses_res.count if courses_res.count is not None else 0
        
        # 3. Exam Success Rate (Mock)
        attempts_res = db.table("exam_attempts").select("score").eq("user_id", user["user_id"]).execute()
        avg_score = 0
        if attempts_res.data:
            avg_score = sum([a["score"] for a in attempts_res.data]) / len(attempts_res.data)

        return {
            "points": points,
            "purchased_courses_count": courses_count,
            "average_exam_score": avg_score,
            "rank": "مبتدئ",
            "achievements": []
        }
    except Exception as e:
        print(f"User Stats Error: {e}")
        # Fallback to zeros instead of 500
        return {
            "points": 0,
            "purchased_courses_count": 0,
            "average_exam_score": 0,
            "rank": "طالب جديد",
            "achievements": []
        }

@router.delete("/me")
async def delete_account(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """حذف الحساب نهائياً (CASCADE سيتعامل مع البيانات المرتبطة)"""
    try:
        # في الإنتاج، قد نحتاج لحذف المستخدم من Supabase Auth أيضاً
        db.table("users").delete().eq("id", user["user_id"]).execute()
        return {"status": "success", "message": "تم حذف الحساب بنجاح"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في حذف الحساب")
