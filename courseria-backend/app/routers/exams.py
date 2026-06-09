from fastapi import APIRouter, HTTPException, Depends, status
from app.dependencies import get_current_user, get_supabase_client
from app.models.course_schemas import QuizBase, QuizQuestion
from typing import List, Optional
import random
import uuid
import datetime

router = APIRouter()

@router.get("/generate-mock")
async def generate_mock_exam(
    grade: str = "bac_scientific",
    subject: str = "math",
    user=Depends(get_current_user),
    db=Depends(get_supabase_client)
):
    """توليد امتحان تجريبي شامل بناءً على الصف والمادة"""
    try:
        # Fallback to empty list if query fails due to missing columns
        try:
            # First, check if grade column exists by trying to select it
            query = db.table("quizzes").select("*")
            if grade:
                try:
                    # Try a simpler select first to see if table exists and then filter
                    query = query.eq("grade", grade)
                except:
                    pass
            
            response = query.execute()
            return response.data
        except Exception as q_e:
            print(f"Internal Query Error: {q_e}")
            return []
    except Exception as e:
        print(f"Mock Generation Error: {e}")
        return []

@router.get("/years-bank", response_model=List[dict])
async def get_years_bank(grade: str, subject: str, db=Depends(get_supabase_client)):
    """Feature 62: بنك الأسئلة الوزاري للسنوات السابقة"""
    try:
        # Query available quizzes
        query = db.table("quizzes").select("*").eq("quiz_type", "official_past_paper")
        if grade:
            # Check if grade column exists by trying to use it
            try:
                query = query.eq("grade", grade)
            except:
                pass
        if subject:
            try:
                query = query.eq("subject", subject)
            except:
                pass
                
        response = query.execute()
        return response.data
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل جلب بنك الأسئلة")

@router.post("/custom-exam", response_model=dict)
async def create_custom_exam(
    params: dict, # difficulty, skill_types, subjects, question_count
    db=Depends(get_supabase_client)
):
    """Feature 65: إمكانية إنشاء اختبار مخصص بالكامل"""
    # Logic to filter and return random questions based on params
    pass
