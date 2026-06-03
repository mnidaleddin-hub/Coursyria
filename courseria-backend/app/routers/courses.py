from fastapi import APIRouter, HTTPException, Depends, status
from app.models.course_schemas import CourseBase, CourseWithLessons, LessonBase, QuizSubmission
from app.dependencies import get_current_user, get_current_teacher, get_supabase_client
from typing import List
import datetime
import logging

logger = logging.getLogger("courseria.courses")

router = APIRouter()

@router.get("/favorites", response_model=List[dict])
async def get_favorites(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب الكورسات المفضلة للمستخدم الحالي"""
    try:
        response = db.table("favorites").select("course_id, courses(*)").eq("user_id", user["user_id"]).execute()
        return response.data
    except Exception as e:
        logger.error(f"!!! Fetch Favorites Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب المفضلة")

@router.get("/my-courses", response_model=List[dict])
async def get_my_courses(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب الكورسات التي اشترك فيها المستخدم الحالي"""
    try:
        response = db.table("user_courses").select("course_id, courses(*)").eq("user_id", user["user_id"]).execute()
        return response.data
    except Exception as e:
        logger.error(f"!!! Fetch My Courses Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب كورساتك")

# --- قراءة الكورسات (متاحة للجميع/الطلاب مع تفعيل RLS) ---

@router.get("", response_model=List[CourseWithLessons])
@router.get("/", response_model=List[CourseWithLessons], include_in_schema=False)
async def get_courses(db=Depends(get_supabase_client)):
    """جلب جميع الكورسات المتاحة (تخضع لـ RLS)"""
    try:
        response = db.table("courses").select("*, lessons(*)").execute()
        return response.data
    except Exception as e:
        logger.error(f"Supabase Fetch Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب الكورسات")

@router.get("/{course_id}", response_model=CourseWithLessons)
async def get_course_details(course_id: str, db=Depends(get_supabase_client)):
    """جلب تفاصيل كورس معين مع دروسه"""
    try:
        response = db.table("courses").select("*, lessons(*)").eq("id", course_id).maybe_single().execute()
        if not response.data:
            raise HTTPException(status_code=404, detail="الكورس غير موجود")
        return response.data
    except HTTPException as he:
        raise he
    except Exception as e:
        logger.error(f"Course Detail Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب تفاصيل الكورس")

@router.get("/{course_id}/lessons", response_model=List[dict])
async def get_course_lessons(course_id: str, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب دروس كورس معين مع تطبيق حماية المحتوى"""
    try:
        # جلب الدروس مع الملحقات
        response = db.table("lessons").select("*, worksheets(*), solved_tests(*), unsolved_tests(*), exam_reviews(*)").eq("course_id", course_id).order("order_index").execute()
        lessons = response.data if response.data else []
        
        # التحقق من الاشتراك (RLS ستمنع جلب البيانات الحساسة إذا لم يكن مشتركاً، لكننا نفضل إخفاء الروابط برمجياً أيضاً)
        sub_res = db.table("subscriptions").select("*").eq("user_id", user["user_id"]).eq("course_id", course_id).execute()
        is_purchased = len(sub_res.data) > 0

        secured_lessons = []
        for lesson in lessons:
            if not is_purchased and not lesson.get("is_free", False):
                # إخفاء البيانات الحساسة للدروس المقفولة
                lesson["video_url"] = None
                lesson["worksheets"] = []
                lesson["solved_tests"] = []
                lesson["unsolved_tests"] = []
                lesson["exam_reviews"] = []
            secured_lessons.append(lesson)
            
        return secured_lessons
    except Exception as e:
        logger.error(f"Lessons Fetch Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب دروس الكورس")

# --- إدارة الكورسات (خاصة بالمعلمين فقط) ---

@router.post("", status_code=status.HTTP_201_CREATED)
@router.post("/", include_in_schema=False, status_code=status.HTTP_201_CREATED)
async def create_course(
    course: CourseBase, 
    teacher=Depends(get_current_teacher), 
    db=Depends(get_supabase_client)
):
    """إنشاء كورس جديد (للمعلمين فقط)"""
    try:
        course_data = course.dict()
        course_data["teacher_id"] = teacher["user_id"]
        
        response = db.table("courses").insert(course_data).execute()
        return response.data[0]
    except Exception as e:
        print(f"!!! Course Creation Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إنشاء الكورس")

@router.put("/{course_id}")
async def update_course(
    course_id: str, 
    course_updates: dict, 
    teacher=Depends(get_current_teacher), 
    db=Depends(get_supabase_client)
):
    """تعديل كورس (تطبق RLS لمنع تعديل كورسات الآخرين)"""
    try:
        response = db.table("courses").update(course_updates).eq("id", course_id).execute()
        if not response.data:
            raise HTTPException(status_code=403, detail="غير مصرح لك بتعديل هذا الكورس أو الكورس غير موجود")
        return response.data[0]
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في تحديث الكورس")

@router.delete("/{course_id}")
async def delete_course(
    course_id: str, 
    teacher=Depends(get_current_teacher), 
    db=Depends(get_supabase_client)
):
    """حذف كورس (تطبق RLS)"""
    try:
        response = db.table("courses").delete().eq("id", course_id).execute()
        if not response.data:
            raise HTTPException(status_code=403, detail="غير مصرح لك بحذف هذا الكورس")
        return {"status": "success", "message": "تم حذف الكورس بنجاح"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في حذف الكورس")

@router.put("/{course_id}/reorder-lessons")
async def reorder_lessons(
    course_id: str, 
    lesson_order: List[str], 
    teacher=Depends(get_current_teacher), 
    db=Depends(get_supabase_client)
):
    """إعادة ترتيب دروس الكورس"""
    try:
        # التأكد من ملكية الكورس
        course_check = db.table("courses").select("id").eq("id", course_id).maybe_single().execute()
        if not course_check.data:
            raise HTTPException(status_code=403, detail="غير مصرح لك بإدارة هذا الكورس")

        for index, lesson_id in enumerate(lesson_order):
            db.table("lessons").update({"order_index": index}).eq("id", lesson_id).eq("course_id", course_id).execute()
            
        return {"status": "success", "message": "تمت إعادة ترتيب الدروس بنجاح"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في إعادة ترتيب الدروس")

# --- ميزات إضافية ---

@router.post("/{course_id}/favorite")
async def toggle_favorite(course_id: str, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """إضافة/إزالة من المفضلة"""
    try:
        existing = db.table("favorites").select("*").eq("user_id", user["user_id"]).eq("course_id", course_id).execute()
        if existing.data:
            db.table("favorites").delete().eq("user_id", user["user_id"]).eq("course_id", course_id).execute()
            return {"status": "removed", "message": "تمت الإزالة من المفضلة"}
        else:
            db.table("favorites").insert({"user_id": user["user_id"], "course_id": course_id}).execute()
            return {"status": "added", "message": "تمت الإضافة إلى المفضلة"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل تحديث المفضلة")

@router.get("/lessons/{lesson_id}/stream")
async def stream_lesson_video(lesson_id: str, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """رابط الفيديو الآمن (يخضع لـ RLS)"""
    try:
        lesson_res = db.table("lessons").select("video_url, is_free").eq("id", lesson_id).single().execute()
        if not lesson_res.data:
            raise HTTPException(status_code=404, detail="الدرس غير موجود")
        
        # إذا لم يكن الدرس مجانياً، RLS ستفشل الاستعلام إذا لم يكن هناك اشتراك
        # (بافتراض وجود سياسة RLS على جدول الدروس تتحقق من الاشتراكات)
        
        return {"url": lesson_res.data.get("video_url")}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في جلب رابط الفيديو")

@router.post("/lessons/{lesson_id}/quiz/submit")
async def submit_quiz(lesson_id: str, submission: QuizSubmission, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """إرسال نتائج الاختبار وتخزينها"""
    try:
        questions_res = db.table("quiz_questions").select("*").eq("lesson_id", lesson_id).order("order_index").execute()
        questions = questions_res.data or []
        
        score = sum(1 for i, q in enumerate(questions) if i < len(submission.answers) and submission.answers[i] == q["correct_option_index"])
        
        db.table("quiz_submissions").insert({
            "user_id": user["user_id"],
            "lesson_id": lesson_id,
            "score": score,
            "total_questions": len(questions),
            "created_at": datetime.datetime.utcnow().isoformat()
        }).execute()
        
        return {"score": score, "total": len(questions)}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في إرسال الاختبار")
