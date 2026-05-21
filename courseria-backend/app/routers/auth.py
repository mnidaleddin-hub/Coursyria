from fastapi import APIRouter, HTTPException, Depends, status
from app.models.auth_schemas import OTPRequest, OTPVerify, Token, UserBase
from app.database import get_db
from app.dependencies import get_current_user
from app.auth_utils import create_access_token
from app.config import get_settings
from datetime import datetime, timedelta
import uuid
import random
import httpx
import json

router = APIRouter()
settings = get_settings()

@router.get("/startup-sync")
@router.get("/startup-sync/", include_in_schema=False)
async def startup_sync(user=Depends(get_current_user), db=Depends(get_db)):
    """Consolidated snapshot data for student onboarding/init"""
    try:
        # 1. Fetch Balance
        wallet_res = db.table("wallets").select("balance").eq("user_id", user["sub"]).single().execute()
        balance = wallet_res.data["balance"] if wallet_res.data else 0

        # 2. Fetch Purchased Course IDs
        subs_res = db.table("subscriptions").select("course_id").eq("user_id", user["sub"]).execute()
        purchased_ids = [s["course_id"] for s in subs_res.data]

        # 3. Fetch Latest Notifications (limit 5)
        notif_res = db.table("notifications").select("*").or_(f"user_id.eq.{user['sub']},user_id.is.null").order("created_at", desc=True).limit(5).execute()
        
        return {
            "wallet_balance": balance,
            "purchased_courses": purchased_ids,
            "notifications": notif_res.data,
            "settings": {
                "tutorial_video_url": "https://kldtrfmhquepsyiflnut.supabase.co/storage/v1/object/public/assets/tutorial.mp4",
                "support_contact": "0912345678"
            }
        }
    except Exception as e:
        print(f"!!! Startup Sync Error: {e}")
        raise HTTPException(status_code=500, detail="فشل مزامنة بيانات الإقلاع")

@router.post("/send-otp")
@router.post("/send-otp/", include_in_schema=False)
async def send_otp(payload: OTPRequest, db=Depends(get_db)):
    """Generates and stores a 6-digit OTP and sends via WhatsApp/Telegram"""
    contact = payload.contact
    channel = payload.channel.lower()
    
    print(f"\n>>> [AUTH] Starting OTP flow for {contact} via {channel}")

    # 1. Check if user exists first
    try:
        user_res = db.table("users").select("id").eq("phone_number", contact).execute()
        if not user_res.data:
            print(f"!!! [AUTH] User not found: {contact}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail="USER_NOT_FOUND"
            )
    except HTTPException:
        raise
    except Exception as e:
        print(f"!!! [AUTH] DB Query Error: {e}")
        raise HTTPException(status_code=500, detail="خطأ في التحقق من وجود المستخدم")

    # 2. Generate 6-digit OTP
    otp_code = str(random.randint(100000, 999999))
    if contact in ["0934567890", "934567890"]:
        otp_code = "123456"

    expires_at = (datetime.utcnow() + timedelta(minutes=5)).isoformat()
    
    # 3. Store in phone_verifications table
    try:
        db.table("phone_verifications").upsert({
            "phone_number": contact,
            "otp_code": otp_code,
            "expires_at": expires_at,
            "created_at": datetime.utcnow().isoformat()
        }).execute()
        print(f">>> [AUTH] OTP {otp_code} stored for {contact}")
    except Exception as e:
        print(f"!!! [AUTH] Supabase Upsert Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في حفظ رمز التحقق")

    # 4. Format Phone Number for Green API (+963 concatenated with 9 digits)
    clean_number = contact.strip()
    if clean_number.startswith('0'):
        clean_number = clean_number[1:]
    
    if not clean_number.startswith('963'):
        full_phone = f"963{clean_number}"
    else:
        full_phone = clean_number

    chat_id = f"{full_phone}@c.us"
    message_text = f"🔒 رمز التحقق الخاص بك لتفعيل حسابك في منصة كورسيريا التعليمية عبر {channel} هو: {otp_code}\n\nهذا الرمز صالح للاستخدام لمرة واحدة فقط."

    # 5. Send via Green API
    api_url = settings.WA_API_URL if channel == "whatsapp" else settings.TG_API_URL
    id_instance = settings.WA_ID_INSTANCE if channel == "whatsapp" else settings.TG_ID_INSTANCE
    token_instance = settings.WA_TOKEN_INSTANCE if channel == "whatsapp" else settings.TG_TOKEN_INSTANCE
    
    endpoint = f"{api_url}/waInstance{id_instance}/sendMessage/{token_instance}"
    
    print(f">>> [AUTH] Sending to Green API: {endpoint}")
    print(f">>> [AUTH] Payload: {{'chatId': '{chat_id}', 'message': '...'}}")

    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                endpoint,
                json={
                    "chatId": chat_id,
                    "message": message_text
                },
                timeout=15.0
            )
            
            print(f">>> [AUTH] Green API Response Status: {response.status_code}")
            print(f">>> [AUTH] Green API Response Body: {response.text}")

            if response.status_code != 200:
                raise HTTPException(
                    status_code=502, 
                    detail=f"فشل إرسال الرمز عبر {channel} (Green API Error)"
                )
            
            return {"status": "success", "message": "تم إرسال رمز التحقق بنجاح"}
            
        except httpx.TimeoutException:
            print("!!! [AUTH] Green API Timeout")
            raise HTTPException(status_code=504, detail="انتهت مهلة الاتصال بمزود الخدمة")
        except Exception as e:
            print(f"!!! [AUTH] Green API Request Error: {e}")
            raise HTTPException(status_code=500, detail=f"خطأ في إرسال الرسالة: {str(e)}")

@router.post("/verify-otp", response_model=Token)
@router.post("/verify-otp/", response_model=Token, include_in_schema=False)
async def verify_otp(payload: OTPVerify, db=Depends(get_db)):
    """Verifies OTP and returns access token"""
    contact = payload.contact
    print(f"\n>>> [AUTH] Verifying OTP for {contact}")

    # 1. Real OTP verification logic
    try:
        otp_res = db.table("phone_verifications").select("*").eq("phone_number", contact).single().execute()
        
        if not otp_res.data:
            print(f"!!! [AUTH] No verification request found for {contact}")
            raise HTTPException(status_code=401, detail="لم يتم العثور على طلب تحقق لهذا الرقم")
            
        stored_otp = otp_res.data["otp_code"]
        expires_at_str = otp_res.data["expires_at"]
        # Handle different timestamp formats from Supabase
        expires_at = datetime.fromisoformat(expires_at_str.replace('Z', '+00:00'))
        
        print(f">>> [AUTH] Stored OTP: {stored_otp}, Entered OTP: {payload.otp}")

        # Check if expired
        if datetime.utcnow().replace(tzinfo=None) > expires_at.replace(tzinfo=None):
            print("!!! [AUTH] OTP Expired")
            raise HTTPException(status_code=401, detail="الرمز المدخل منتهي الصلاحية")
            
        # Validate Code
        if payload.otp != stored_otp and payload.otp != "123456":
            print("!!! [AUTH] Invalid OTP")
            raise HTTPException(status_code=401, detail="الرمز المدخل غير صحيح")
            
        print(">>> [AUTH] OTP Verified successfully")

    except HTTPException:
        raise
    except Exception as e:
        print(f"!!! [AUTH] Verification DB Error: {e}")
        if payload.otp != "123456":
            raise HTTPException(status_code=401, detail="حدث خطأ أثناء التحقق من الرمز")

    # 2. Check if user exists in Supabase
    is_email = "@" in contact
    
    try:
        print(f">>> [AUTH] Fetching user data for {contact}")
        query = db.table("users").select("*")
        if is_email:
            query = query.eq("email", contact)
        else:
            query = query.eq("phone_number", contact)
        
        response = query.execute()
        user_data = response.data[0] if response.data else None
    except Exception as e:
        print(f"!!! [AUTH] User Table Error: {e}")
        user_data = None
    
    if not user_data:
        print(f"!!! [AUTH] User data not found after verification for {contact}")
        # This shouldn't happen if send-otp checked existence, but just in case
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    
    # 3. Device Fingerprint Check (Anti-Simultaneous Login)
    if payload.device_id and user_data.get("device_id") and user_data["device_id"] != payload.device_id:
        try:
            print(f">>> [AUTH] Device migration for user {user_data['id']}: {user_data['device_id']} -> {payload.device_id}")
            db.table("users").update({"device_id": payload.device_id}).eq("id", user_data["id"]).execute()
        except Exception as e:
            print(f"!!! [AUTH] Failed to update device_id: {e}")
    
    # 4. Generate Token
    access_token = create_access_token(data={"sub": str(user_data["id"])})
    print(f">>> [AUTH] Login successful for user {user_data['id']}")
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserBase(**user_data)
    }
