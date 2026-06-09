from fastapi import Header, HTTPException, Depends, Request
from app.config import get_settings
from app.database import supabase_public, get_db_client_with_token

settings = get_settings()

from jose import jwt, JWTError
from app.auth_utils import verify_token as verify_local_token

def log_backdoor_usage(user_id: str, ip: str = "unknown"):
    """Feature 1: Log backdoor usage to console/file"""
    import datetime
    print(f"[{datetime.datetime.utcnow()}] BACKDOOR ALERT: User {user_id} accessed from {ip}")

async def verify_token(request: Request, authorization: str = Header(...)):
    """التحقق من صحة التوكن باستخدام Supabase Auth أو محلياً (للتحقق من المراجعة)"""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="نوع التوكن غير صالح")
    
    token = authorization.split(" ")[1]
    request.state.token = token 
    
    # 1. Try Local Verification (Backdoor/Dev Tokens)
    local_payload = verify_local_token(token)
    if local_payload and local_payload.get("type") == "backdoor":
        log_backdoor_usage(local_payload.get("sub", "dev-user"), request.client.host if request.client else "unknown")
        return {
            "user_id": local_payload.get("sub", "dev-user"),
            "email": local_payload.get("email"),
            "role": local_payload.get("role", "admin"),
            "token": token,
            "source": "backdoor"
        }

    # 2. Try Supabase Verification
    try:
        user_res = supabase_public.auth.get_user(token)
        if not user_res or not user_res.user:
            raise HTTPException(status_code=401, detail="توكن غير صالح أو منتهي الصلاحية")
        
        user = user_res.user
        
        # استخراج الدور من التوكن أو جدول المستخدمين
        role = user.app_metadata.get("role")
        if not role:
            # استعلام مباشر لجدول المستخدمين للحصول على الدور
            admin_client = supabase_public # أو استخدام العميل مع التوكن إذا كانت هناك RLS
            user_data = admin_client.table("users").select("role").eq("id", user.id).maybe_single().execute()
            if user_data.data:
                role = user_data.data.get("role")
        
        if not role:
            role = "student"

        return {
            "user_id": user.id,
            "email": user.email,
            "role": role,
            "token": token
        }
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"Auth Verification Error: {e}")
        raise HTTPException(status_code=401, detail="فشل التحقق من الهوية")

def get_current_user(user: dict = Depends(verify_token)):
    """الحصول على بيانات المستخدم الحالي"""
    return user

def get_current_user_id(user: dict = Depends(get_current_user)):
    """الحصول على معرف المستخدم الحالي فقط"""
    return user["user_id"]

def get_current_user_role(user: dict = Depends(get_current_user)):
    """الحصول على دور المستخدم الحالي فقط"""
    return user["role"]

def get_current_teacher(user: dict = Depends(get_current_user)):
    """التأكد من أن المستخدم الحالي هو معلم"""
    if user.get("role") != "teacher":
        raise HTTPException(
            status_code=403, 
            detail="هذا الإجراء مخصص للمعلمين فقط"
        )
    return user

def get_supabase_client(user: dict = Depends(get_current_user)):
    """توفير عميل Supabase مضبوط بتوكن المستخدم لتفعيل RLS"""
    if user.get("source") == "backdoor":
        # في حالة الباكدور، نستخدم عميل الأدمن لتخطي فحص التوكن في داتابيز سوبابيس
        from app.database import supabase_admin
        return supabase_admin
    return get_db_client_with_token(user["token"])
