from fastapi import APIRouter
from app.config import get_settings

router = APIRouter()
settings = get_settings()

@router.get("/version-check")
@router.get("/version-check/", include_in_schema=False)
async def version_check():
    """Returns the latest app version and download URL for OTA updates"""
    return {
        "latest_version": "1.0.0",
        "min_required_version": "1.0.0",
        "is_mandatory": False,
        "download_url": "https://storage.supabase.co/coursyria/releases/app-release.apk",
        "release_notes": "تحسينات في سرعة تشغيل الفيديوهات وإصلاحات عامة."
    }
