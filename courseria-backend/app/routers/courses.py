from fastapi import APIRouter, HTTPException, Depends, status
from app.models.course_schemas import CourseBase, CourseWithLessons, LessonBase, QuizSubmission
from app.database import get_db
from app.dependencies import get_current_user
from typing import List
import datetime

router = APIRouter()

MOCK_COURSES = [
    {
        "id": "c1", 
        "title": "Mathematics for Baccalaureate", 
        "instructor": "Prof. Ahmad", 
        "price": 50000.0, 
        "subject": "رياضيات", 
        "rating": 4.8,
        "cover_url": "https://placehold.co/600x400",
        "created_at": datetime.datetime.utcnow().isoformat(),
        "is_purchased": False,
        "lessons": [
            {
                "id": "l1",
                "title": "مقدمة عن المادة",
                "duration": "10:00",
                "video_url": "https://example.com/video1",
                "is_free": True
            },
            {
                "id": "l2",
                "title": "الدرس الأول: التوابع",
                "duration": None, # Testing optional duration
                "video_url": "https://example.com/video2",
                "is_free": False
            }
        ]
    },
    {
        "id": "c2", 
        "title": "Physics Advanced", 
        "instructor": "Dr. Layla", 
        "price": 45000.0, 
        "subject": "فيزياء", 
        "rating": 4.9,
        "cover_url": "https://placehold.co/600x400",
        "created_at": datetime.datetime.utcnow().isoformat(),
        "is_purchased": False,
        "lessons": []
    },
]

@router.get("/contributors", response_model=List[dict])
@router.get("/contributors/", include_in_schema=False)
async def get_contributors(db=Depends(get_db)):
    """Fetch core team and contributors"""
    try:
        response = db.table("contributors").select("*").order("role").execute()
        return response.data
    except Exception as e:
        print(f"!!! Contributors Fetch Error: {e}")
        return []

@router.get("/favorites", response_model=List[CourseBase])
@router.get("/favorites/", response_model=List[CourseBase], include_in_schema=False)
async def get_favorite_courses(user=Depends(get_current_user), db=Depends(get_db)):
    """Fetch all bookmarked courses for the current user"""
    try:
        response = db.table("favorites").select("course_id, courses(*)").eq("user_id", user["sub"]).execute()
        # Flatten the response to return course objects
        favorites = [fav["courses"] for fav in response.data if fav.get("courses")]
        return favorites
    except Exception as e:
        print(f"!!! Favorites Fetch Error: {e}")
        return []

@router.post("/{course_id}/favorite")
@router.post("/{course_id}/favorite/", include_in_schema=False)
async def toggle_favorite(course_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    """Toggle bookmark/unbookmark for a course"""
    try:
        # Check if already favorited
        existing = db.table("favorites").select("*").eq("user_id", user["sub"]).eq("course_id", course_id).execute()
        
        if existing.data:
            # Unfavorite
            db.table("favorites").delete().eq("user_id", user["sub"]).eq("course_id", course_id).execute()
            return {"status": "removed", "message": "تمت الإزالة من المفضلة"}
        else:
            # Favorite
            db.table("favorites").insert({
                "user_id": user["sub"],
                "course_id": course_id,
                "created_at": datetime.datetime.utcnow().isoformat()
            }).execute()
            return {"status": "added", "message": "تمت الإضافة إلى المفضلة"}
    except Exception as e:
        print(f"!!! Toggle Favorite Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في تحديث المفضلة")

@router.get("/lessons/{lesson_id}/stream")
async def stream_lesson_video(lesson_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    """Authenticated gatekeeper for secure video streaming"""
    try:
        # 1. Fetch lesson details
        lesson_res = db.table("lessons").select("*, courses(id, is_free_course)").eq("id", lesson_id).single().execute()
        if not lesson_res.data:
            raise HTTPException(status_code=404, detail="الدرس غير موجود")
        
        lesson = lesson_res.data
        course_id = lesson["course_id"]
        
        # 2. Authorization Check
        # Check if lesson is free OR if student has a valid purchase
        is_lesson_free = lesson.get("is_free", False)
        
        if not is_lesson_free:
            sub_res = db.table("subscriptions").select("*").eq("user_id", user["sub"]).eq("course_id", course_id).execute()
            if not sub_res.data:
                raise HTTPException(status_code=403, detail="يجب شراء الكورس لمشاهدة هذا الدرس")

        # 3. Generate Signed URL or Proxy the Supabase Storage URL
        # For production, we'd use Supabase Storage 'create_signed_url'
        # Here we return the URL for the client player to consume
        video_url = lesson.get("video_url")
        if not video_url:
             raise HTTPException(status_code=404, detail="رابط الفيديو غير متوفر")

        return {"url": video_url}
        
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"!!! Video Stream Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب رابط الفيديو الآمن")

@router.post("/lessons/{lesson_id}/quiz/submit")
async def submit_quiz(lesson_id: str, submission: QuizSubmission, user=Depends(get_current_user), db=Depends(get_db)):
    """Score a quiz submission and save metadata"""
    try:
        # 1. Fetch correct answers for the lesson
        questions_res = db.table("quiz_questions").select("*").eq("lesson_id", lesson_id).order("order_index").execute()
        questions = questions_res.data if questions_res.data else []
        
        if not questions:
            raise HTTPException(status_code=404, detail="لا توجد أسئلة لهذا الاختبار")
            
        # 2. Calculate Score
        score = 0
        total = len(questions)
        results = []
        
        for i, q in enumerate(questions):
            user_answer = submission.answers[i] if i < len(submission.answers) else -1
            is_correct = user_answer == q["correct_option_index"]
            if is_correct:
                score += 1
            results.append({"question_id": q["id"], "is_correct": is_correct})
            
        # 3. Save to Supabase
        db.table("quiz_submissions").insert({
            "user_id": user["sub"],
            "lesson_id": lesson_id,
            "score": score,
            "total_questions": total,
            "created_at": datetime.datetime.utcnow().isoformat()
        }).execute()
        
        return {
            "status": "success",
            "score": score,
            "total": total,
            "percentage": (score / total) * 100 if total > 0 else 0
        }
    except Exception as e:
        print(f"!!! Quiz Submission Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إرسال نتائج الاختبار")

@router.get("", response_model=List[CourseWithLessons])
@router.get("/", response_model=List[CourseWithLessons], include_in_schema=False)
async def get_courses(db=Depends(get_db)):
    try:
        # 1. Real Supabase data retrieval
        response = db.table("courses").select("*, lessons(*)").execute()
        
        if response.data and len(response.data) > 0:
            return response.data
            
        # 2. Fallback to MOCK_COURSES only if DB is empty
        return MOCK_COURSES
    except Exception as e:
        print(f"!!! Supabase Pipeline Error: {e}")
        return MOCK_COURSES

@router.get("/{course_id}", response_model=CourseWithLessons)
async def get_course_details(course_id: str, db=Depends(get_db)):
    try:
        # We fetch course with its lessons for the details page
        response = db.table("courses").select("*, lessons(*)").eq("id", course_id).single().execute()
        if response.data:
            return response.data
        
        # Fallback for mock courses in case DB doesn't have it
        mock = next((c for c in MOCK_COURSES if c["id"] == course_id), None)
        if mock:
            return mock
            
        raise HTTPException(status_code=404, detail="الكورس غير موجود")
    except Exception as e:
        print(f"!!! Course Detail Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب تفاصيل الكورس")

@router.get("/{course_id}/lessons", response_model=List[LessonBase])
async def get_course_lessons(course_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        # 1. Fetch lessons with their related assets
        # We assume tables: lesson_worksheets, lesson_solved_tests, etc.
        response = db.table("lessons").select("*, worksheets(*), solved_tests(*), unsolved_tests(*), exam_reviews(*)").eq("course_id", course_id).order("order_index").execute()
        lessons = response.data if response.data else []
        
        # 2. Apply Security: Lock lessons and assets based on purchase status
        sub_res = db.table("subscriptions").select("*").eq("user_id", user["sub"]).eq("course_id", course_id).execute()
        is_purchased = len(sub_res.data) > 0

        secured_lessons = []
        for lesson in lessons:
            # First lesson is usually free (is_free: True), others depend on is_purchased
            if not is_purchased and not lesson.get("is_free", False):
                # Mask sensitive data for locked lessons
                lesson["video_url"] = None
                lesson["worksheets"] = []
                lesson["solved_tests"] = []
                lesson["unsolved_tests"] = []
                lesson["exam_reviews"] = []
            secured_lessons.append(lesson)

        if not secured_lessons:
             # Fallback to mock lessons if DB is empty
            mock = next((c for c in MOCK_COURSES if c["id"] == course_id), None)
            return mock["lessons"] if mock else []
            
        return secured_lessons
    except Exception as e:
        print(f"!!! Lessons Fetch Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب دروس الكورس")

@router.get("/{course_id}/video/{video_id}")
async def get_video_stream(
    course_id: str, 
    video_id: str, 
    user=Depends(get_current_user), 
    db=Depends(get_db)
):
    # 1. Check if user is subscribed to course (In a real scenario)
    # subscription = db.table("subscriptions").select("*").eq("user_id", user["user_id"]).eq("course_id", course_id).execute()
    # if not subscription.data:
    #     raise HTTPException(status_code=403, detail="Not subscribed to this course")

    # 2. Generate secure, time-limited playback streaming URL
    # This is a mock implementation for a secure CDN URL
    mock_video_url = f"https://cdn.coursyria.com/streams/{course_id}/{video_id}/playlist.m3u8?token=secure_temp_token"
    
    # 3. AES-128 Decryption Key for offline local player decryption
    # In production, this would be fetched from a secure key management system
    mock_aes_key = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6" # 32 chars for AES-128 hex or 16 bytes
    
    expiry_time = (datetime.datetime.utcnow() + datetime.timedelta(hours=24)).isoformat()

    return {
        "video_url": mock_video_url,
        "decryption_key": mock_aes_key,
        "expiry": expiry_time
    }
