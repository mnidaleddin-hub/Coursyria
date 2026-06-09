from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
import hashlib
import datetime
import time

start_time = datetime.datetime.utcnow()

# Configure Loguru
from loguru import logger
import sys

logger.remove()
logger.add(sys.stdout, format="{time} {level} {message}", level="INFO")
logger.add("app.log", rotation="10 MB")

print("Loading settings...")
from app.config import get_settings
settings = get_settings()
print(f"Environment: {settings.ENV}")

print("Loading routers...")
from app.routers import auth, courses, wallet, admin, notifications, system, exams, community, chat, ai, user
print("Routers loaded successfully")

app = FastAPI(
    title="Courseria API",
    description="E-learning platform backend optimized for Syrian students",
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
)

# Maintenance Mode Middleware
@app.middleware("http")
async def maintenance_middleware(request: Request, call_next):
    # Check if maintenance mode is active (can be stored in a variable or DB)
    is_maintenance = False # Logic to fetch from DB/Cache
    if is_maintenance and not request.url.path.startswith("/admin") and request.url.path != "/health":
        return JSONResponse(
            status_code=503,
            content={"detail": "التطبيق في وضع الصيانة حالياً. يرجى المحاولة لاحقاً."}
        )
    return await call_next(request)

# ETag Middleware
@app.middleware("http")
async def etag_middleware(request: Request, call_next):
    response = await call_next(request)
    
    # فقط للـ GET requests التي تنجح ونوع الـ response ليس Streaming
    if request.method == "GET" and response.status_code == 200:
        try:
            # محاولة قراءة body إذا كان موجوداً
            if hasattr(response, 'body') and response.body:
                etag = hashlib.md5(response.body).hexdigest()
                if request.headers.get("If-None-Match") == etag:
                    return JSONResponse(status_code=304, content=None)
                response.headers["ETag"] = etag
        except AttributeError:
            # إذا كان الـ response من نوع Streaming، نتخطى إضافة ETag
            pass
    
    return response
# Gzip Compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Custom Exception Handler for DB/Table missing errors
from postgrest.exceptions import APIError

@app.exception_handler(APIError)
async def postgrest_exception_handler(request: Request, exc: APIError):
    # If table or column not found, return empty list/200 instead of 500
    if "PGRST204" in str(exc) or "PGRST205" in str(exc) or "42703" in str(exc):
        return JSONResponse(
            status_code=200,
            content={"status": "warning", "message": "الميزة غير متوفرة حالياً", "data": []}
        )
    return JSONResponse(
        status_code=400,
        content={"status": "error", "message": str(exc)}
    )

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Log the full error
    import traceback
    traceback.print_exc()
    
    # Check if it's a 404 already
    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail}
        )

    # Generic error handling
    return JSONResponse(
        status_code=500,
        content={"status": "error", "message": "حدث خطأ داخلي في السيرفر"}
    )

# CORS Middleware setup
origins = settings.ALLOWED_ORIGINS.split(",")
if "https://coursyria-api.onrender.com" not in origins:
    origins.append("https://coursyria-api.onrender.com")
if "https://coursyria.onrender.com" not in origins:
    origins.append("https://coursyria.onrender.com")

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if settings.is_production else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def extract_token_to_state(request: Request, call_next):
    """استخراج التوكن وتخزينه في حالة الطلب للوصول السريع"""
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        request.state.token = auth_header.split(" ")[1]
    else:
        request.state.token = None
    
    response = await call_next(request)
    return response

@app.middleware("http")
async def log_requests(request, call_next):
    logger.info(f"--> Incoming Request: {request.method} {request.url.path}")
    try:
        response = await call_next(request)
        logger.info(f"<-- Response Status: {response.status_code}")
        return response
    except Exception as e:
        logger.critical(f"!!! CRITICAL BACKEND ERROR: {str(e)}")
        raise e

# Root health-check endpoint
@app.get("/")
@app.get("/health")
async def health_check():
    # Check DB Connection
    try:
        from app.database import supabase_public
        supabase_public.table("users").select("id").limit(1).execute()
        db_status = "connected"
    except:
        db_status = "disconnected"

    return {
        "status": "ok",
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "database": db_status,
        "version": "1.1.0-mvp",
        "uptime": (datetime.datetime.utcnow() - start_time).total_seconds()
    }

# Mounting routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(courses.router, prefix="/courses", tags=["Courses"])
app.include_router(wallet.router, prefix="/wallet", tags=["Wallet"])
app.include_router(admin.router, prefix="/admin", tags=["Backoffice Administration"])
app.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
app.include_router(system.router, prefix="/system", tags=["System & Updates"])
app.include_router(exams.router, prefix="/exams", tags=["Exam Simulator"])
app.include_router(community.router, prefix="/community", tags=["Community"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(ai.router, prefix="/ai", tags=["AI Services"])
app.include_router(user.router, prefix="/user", tags=["User Profile"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
