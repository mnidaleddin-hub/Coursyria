from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class LessonAsset(BaseModel):
    id: str
    title: str
    asset_type: str  # pdf, quiz, test_paper, review
    file_url: str
    is_solved: Optional[bool] = None

class QuizQuestion(BaseModel):
    id: str
    question_text: str
    options: List[str]
    correct_option_index: int
    difficulty: str = "medium"  # easy, medium, hard, exam
    skill_type: str = "comprehension"  # comprehension, application, analysis, synthesis
    explanation: Optional[str] = None
    video_explanation_url: Optional[str] = None
    timestamp_start: Optional[int] = None
    timestamp_end: Optional[int] = None

class QuizBase(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    quiz_type: str = "standard"  # lesson_quiz, mock_exam, custom
    grade: Optional[str] = None  # 9th, bac_scientific, bac_literary
    subject: Optional[str] = None
    time_limit: Optional[int] = None
    passing_score: int = 60
    is_published: bool = True
    questions_count: int = 0
    created_at: datetime

class QuizSubmission(BaseModel):
    lesson_id: str
    answers: List[int]  # List of selected indices

class LessonBase(BaseModel):
    id: str
    course_id: str
    title: str
    content: Optional[str] = None
    video_url: Optional[str] = None
    duration_minutes: int = 0
    order_index: int = 0
    is_free: bool = False
    created_at: Optional[datetime] = None
    # Extra fields
    likes_count: int = 0
    views_count: int = 0
    thumbnail_url: Optional[str] = None
    video_description: Optional[str] = None
    # Optional fields for joined data
    worksheets: List[LessonAsset] = []
    solved_tests: List[LessonAsset] = []
    unsolved_tests: List[LessonAsset] = []
    exam_reviews: List[LessonAsset] = []
    quiz_questions: List[QuizQuestion] = []

class CourseReview(BaseModel):
    id: str
    user_name: str
    rating: int
    comment: str
    created_at: datetime

class CourseBase(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    price: float
    teacher_id: Optional[str] = None
    difficulty: str = "medium"
    duration_hours: int = 0
    is_published: bool = True
    created_at: Optional[datetime] = None

class CourseWithLessons(CourseBase):
    lessons: List[LessonBase]

class UserSubscription(BaseModel):
    user_id: str
    course_id: str
    purchased_at: datetime
