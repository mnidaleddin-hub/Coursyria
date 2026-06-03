from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
print("Loading settings...")
from app.config import get_settings
settings = get_settings()
print(f"Environment: {settings.ENV}")

print("Loading routers...")
from app.routers import auth, courses, wallet, admin, notifications, system
print("Routers loaded successfully")

import logging
import sys

# Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("courseria")

app = FastAPI(
    title="Courseria API",
    description="E-learning platform backend optimized for Syrian students",
    version="1.0.0",
    docs_url="/docs" if not settings.is_production else None,
    redoc_url="/redoc" if not settings.is_production else None,
)

# Global Exception Handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    logger.error(f"!!! UNHANDLED ERROR: {str(exc)}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "حدث خطأ داخلي في الخادم، يرجى المحاولة لاحقاً"},
    )

# Global Routing Configuration
app.router.redirect_slashes = True

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
        logger.critical(f"!!! CRITICAL BACKEND ERROR: {str(e)}", exc_info=True)
        raise e

# Root health-check endpoint
@app.get("/")
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "version": "1.0.0",
        "environment": settings.ENV,
        "timestamp": "2026-05-13" # In production, use dynamic datetime
    }

# Mounting routers
app.include_router(auth.router, prefix="/auth", tags=["Authentication"])
app.include_router(courses.router, prefix="/courses", tags=["Courses"])
app.include_router(wallet.router, prefix="/wallet", tags=["Wallet"])
app.include_router(admin.router, prefix="/admin", tags=["Backoffice Administration"])
app.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
app.include_router(system.router, prefix="/system", tags=["System & Updates"])

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
