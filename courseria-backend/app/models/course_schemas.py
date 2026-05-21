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
    explanation: Optional[str] = None

class QuizSubmission(BaseModel):
    lesson_id: str
    answers: List[int]  # List of selected indices

class LessonBase(BaseModel):
    id: str
    title: str
    duration: Optional[str] = None
    video_url: Optional[str] = None
    is_free: bool = False
    order_index: int = 0
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
    instructor: str
    price: float
    subject: str
    rating: float = 0.0
    cover_url: Optional[str] = None
    created_at: datetime
    is_purchased: bool = False
    reviews: List[CourseReview] = []

class CourseWithLessons(CourseBase):
    lessons: List[LessonBase]

class UserSubscription(BaseModel):
    user_id: str
    course_id: str
    purchased_at: datetime
