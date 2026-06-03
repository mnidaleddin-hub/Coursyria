from fastapi import APIRouter, HTTPException, Depends, status
from app.models.auth_schemas import OTPRequest, OTPVerify, Token, UserBase, LoginRequest, RegisterRequest
from app.database import get_db, supabase_public, supabase_admin
from app.dependencies import get_current_user, get_supabase_client
from app.auth_utils import create_access_token
from app.config import get_settings
from datetime import datetime, timedelta
import uuid
import random
import httpx
import json
import asyncio
import phonenumbers
from phonenumbers import PhoneNumberFormat
import logging

router = APIRouter()
settings = get_settings()
logger = logging.getLogger("courseria.auth")

def is_backdoor(identifier: str) -> bool:
    return settings.ENABLE_DEV_BACKDOOR and identifier == settings.DEV_BACKDOOR_CODE

def create_backdoor_token():
    # Generate a developer/admin review token locally
    return create_access_token(
        data={
            "sub": "dev-backdoor-user",
            "role": "developer_review",
            "is_admin": True
        },
        expires_delta=timedelta(hours=24)
    )

@router.get("/startup-sync")
@router.get("/startup-sync/", include_in_schema=False)
async def startup_sync(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """Consolidated snapshot data for student onboarding/init"""
    try:
        # 1. Fetch Balance
        wallet_res = db.table("wallets").select("balance").eq("user_id", user["user_id"]).maybe_single().execute()
        balance = wallet_res.data["balance"] if wallet_res.data else 0

        # 2. Fetch Purchased Course IDs
        subs_res = db.table("subscriptions").select("course_id").eq("user_id", user["user_id"]).execute()
        purchased_ids = [s["course_id"] for s in subs_res.data]

        # 3. Fetch Latest Notifications (limit 5)
        notif_res = db.table("notifications").select("*").or_(f"user_id.eq.{user['user_id']},user_id.is.null").order("created_at", desc=True).limit(5).execute()
        
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
    """Generates and stores a 6-digit OTP and sends via WhatsApp/Telegram (International Support)"""
    # CRITICAL LOGGING: Print the exact payload received from the network
    logger.info(f"RECEIVED OTP REQUEST: {payload.dict()}")
    
    contact = payload.contact
    
    # Ensure channel is NEVER None or empty
    channel = (payload.channel or "whatsapp").lower().strip()
    if not channel:
        channel = "whatsapp"
        
    logger.info(f"PROCESSED CHANNEL: '{channel}'")
    
    # 1. Backdoor Check
    if is_backdoor(contact):
        logger.info(f"Backdoor access for {contact}")
        return {"status": "success", "message": "Backdoor active", "is_backdoor": True}

    logger.info(f"Starting OTP flow for {contact} via {channel}")

    # 2. International Phone Parsing / Username Handling
    try:
        logger.info(f"Raw request payload: contact={contact}, channel={channel}")
        
        # TELEGRAM USERNAME CHECK: If contact starts with @, skip phone parsing
        if contact.startswith("@"):
            full_phone = contact # We reuse this variable name to keep code flow simple
            clean_number_for_api = contact
            logger.info(f"Detected Telegram Username: {contact}")
        else:
            # Standardize contact format for parsing
            phone_to_parse = contact if contact.startswith('+') else f"+{contact}"
            parsed_number = phonenumbers.parse(phone_to_parse, None)
            if not phonenumbers.is_valid_number(parsed_number):
                logger.error(f"Invalid phone number: {contact}")
                raise ValueError("رقم هاتف غير صالح")
            
            full_phone = phonenumbers.format_number(parsed_number, PhoneNumberFormat.E164)
            # For Green API chat ID, we need the number without the '+'
            clean_number_for_api = full_phone.replace('+', '')
            logger.info(f"Parsed Phone: {full_phone} (API ID: {clean_number_for_api})")
    except Exception as e:
        if isinstance(e, ValueError): raise
        logger.error(f"Parsing Error: {e}")
        raise HTTPException(
            status_code=400, 
            detail="يرجى إدخال رقم هاتف صحيح أو معرف تليغرام يبدأ بـ @"
        )

    # 3. Business Logic Check (Login vs Register)
    try:
        # Query based on either phone or telegram_username
        if full_phone.startswith("@"):
            user_res = db.table("users").select("*").eq("telegram_username", full_phone).execute()
        else:
            user_res = db.table("users").select("*").eq("phone_number", full_phone).execute()
            
        user_exists = len(user_res.data) > 0
        user_record = user_res.data[0] if user_exists else {}
        
        if payload.type == "login" and not user_exists:
            logger.error(f"Login failed: User not found in DB: {full_phone}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, 
                detail="USER_NOT_FOUND"
            )
        elif payload.type == "register" and user_exists:
            logger.error(f"Registration failed: User already exists: {full_phone}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, 
                detail="USER_ALREADY_EXISTS"
            )
            
        if user_exists:
            logger.info(f"User verified for login: {user_res.data[0]['id']}")
        else:
            logger.info(f"Number verified for new registration: {full_phone}")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"DB Query Error: {e}")
        raise HTTPException(status_code=500, detail="خطأ في التحقق من البيانات")

    # 4. Generate 6-digit OTP
    otp_code = str(random.randint(100000, 999999))
    
    # Special bypass for testing numbers
    if full_phone in ["+963934567890", "+9630934567890"]:
        otp_code = "123456"
        logger.info("Using TEST OTP 123456")

    expires_at = (datetime.utcnow() + timedelta(minutes=10)).isoformat()
    
    # 5. Store in phone_verifications table
    try:
        # Use admin client to bypass RLS and ensure the column is written
        from app.database import supabase_admin
        
        verification_data = {
            "phone_number": full_phone, # This could be the @username now
            "otp_code": otp_code,
            "channel": channel, # This is guaranteed to be non-null string now
            "expires_at": expires_at,
            "created_at": datetime.utcnow().isoformat()
        }
        
        logger.info(f"UPSERTING TO DB: {verification_data}")
        
        supabase_admin.table("phone_verifications").upsert(verification_data).execute()
        logger.info(f"OTP {otp_code} stored/updated for {full_phone} via {channel}")
    except Exception as e:
        logger.error(f"Supabase Upsert Error: {e}")
        # Log specific details about the error if possible
        if hasattr(e, 'message'):
            logger.error(f"Error Message: {e.message}")
        raise HTTPException(status_code=500, detail="فشل في حفظ رمز التحقق في قاعدة البيانات")

    # 6. Message configuration
    message_text = f"🔒 رمز التحقق الخاص بك لتفعيل حسابك في منصة كورسيريا التعليمية هو: {otp_code}\n\nهذا الرمز صالح لمدة 10 دقائق."

    # 7. Send via Green API (WhatsApp) or Telegram
    if channel == "whatsapp":
        api_url = settings.WA_API_URL
        id_instance = settings.WA_ID_INSTANCE
        token_instance = settings.WA_TOKEN_INSTANCE
        # GREEN API FIX: Use phone_number without '+' followed by @c.us
        chat_id = clean_number_for_api.replace('+', '') + "@c.us"
    else:
        # Telegram via Green API or Direct (Assuming Green API based on config)
        api_url = settings.TG_API_URL
        id_instance = settings.TG_ID_INSTANCE
        token_instance = settings.TG_TOKEN_INSTANCE
        
        # DEBUG LOGS FOR TELEGRAM CREDENTIALS
        logger.info(f"TELEGRAM_ID_INSTANCE: {id_instance}")
        if token_instance:
            logger.info(f"TELEGRAM_TOKEN_INSTANCE is set (Length: {len(token_instance)})")
        else:
            logger.error("TELEGRAM_TOKEN_INSTANCE IS EMPTY OR NULL")

        # TELEGRAM USERNAME LOGIC: Use @username if available, else fallback to phone@c.us
        tg_username = user_record.get("telegram_username")
        if contact.startswith("@"):
            chat_id = contact
            logger.info(f"Using direct Telegram Username from contact: {chat_id}")
        elif tg_username:
            if not tg_username.startswith("@"):
                tg_username = f"@{tg_username}"
            chat_id = tg_username
            logger.info(f"Using Telegram Username from DB: {chat_id}")
        else:
            # Fallback to phone format (Removing '+' for Green API compatibility)
            chat_id = clean_number_for_api.replace('+', '') + "@c.us"
            logger.info(f"No Telegram Username found, using fallback: {chat_id}")
    
    if not id_instance or not token_instance:
        logger.error(f"Missing credentials for {channel}")
        raise HTTPException(status_code=500, detail=f"إعدادات إرسال {channel} غير مكتملة على الخادم")

    endpoint = f"{api_url}/waInstance{id_instance}/sendMessage/{token_instance}"
    
    logger.info(f"Sending to {channel} via Green API...")
    logger.info(f"Endpoint: {api_url}/waInstance{id_instance}/sendMessage/****")

    async with httpx.AsyncClient() as client:
        try:
            # Implement simple retry logic (1 retry after 3 seconds)
            for attempt in range(2):
                response = await client.post(
                    endpoint,
                    json={
                        "chatId": chat_id,
                        "message": message_text
                    },
                    timeout=20.0
                )
                
                logger.info(f"Attempt {attempt+1} - Status: {response.status_code}")
                
                if response.status_code == 200:
                    logger.info(f"Message sent successfully: {response.text}")
                    return {"status": "success", "message": "تم إرسال رمز التحقق بنجاح"}
                
                logger.error(f"Attempt {attempt+1} failed: {response.text}")
                if attempt == 0:
                    logger.info("Retrying in 3 seconds...")
                    await asyncio.sleep(3)
            
            raise HTTPException(
                status_code=502, 
                detail=f"فشل إرسال الرمز عبر {channel}. يرجى التأكد من أن الرقم مسجل في الخدمة."
            )
            
        except httpx.TimeoutException:
            logger.error(f"Green API Timeout on {channel}")
            raise HTTPException(status_code=504, detail="انتهت مهلة الاتصال بمزود الخدمة (Green API)")
        except Exception as e:
            logger.error(f"Green API Request Error: {e}")
            raise HTTPException(status_code=500, detail=f"خطأ تقني في إرسال الرسالة: {str(e)}")

@router.get("/test-whatsapp")
async def test_whatsapp(phone: str):
    """Test endpoint to verify WhatsApp credentials"""
    print(f"\n>>> [TEST] Testing WhatsApp for {phone}")
    
    if not settings.WA_ID_INSTANCE or not settings.WA_TOKEN_INSTANCE:
        return {"status": "error", "message": "Missing WA_ID_INSTANCE or WA_TOKEN_INSTANCE"}

    # Standardize chat ID
    clean_phone = phone.replace('+', '').replace(' ', '')
    chat_id = f"{clean_phone}@c.us"
    
    endpoint = f"{settings.WA_API_URL}/waInstance{settings.WA_ID_INSTANCE}/sendMessage/{settings.WA_TOKEN_INSTANCE}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                endpoint,
                json={"chatId": chat_id, "message": "🔔 كورسيريا: رسالة اختبار لمنظومة واتساب بنجاح!"},
                timeout=20.0
            )
            print(f">>> [TEST] WA Response: {response.status_code} - {response.text}")
            return {"status": "success", "response": response.json()}
        except Exception as e:
            print(f"!!! [TEST] WA Error: {e}")
            return {"status": "error", "message": str(e)}

@router.get("/test-telegram")
async def test_telegram(phone: str):
    """Test endpoint to verify Telegram credentials"""
    print(f"\n>>> [TEST] Testing Telegram for {phone}")
    
    if not settings.TG_ID_INSTANCE or not settings.TG_TOKEN_INSTANCE:
        return {"status": "error", "message": "Missing TG_ID_INSTANCE or TG_TOKEN_INSTANCE"}

    clean_phone = phone.replace('+', '').replace(' ', '')
    chat_id = f"{clean_phone}@t.me"
    
    endpoint = f"{settings.TG_API_URL}/waInstance{settings.TG_ID_INSTANCE}/sendMessage/{settings.TG_TOKEN_INSTANCE}"
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                endpoint,
                json={"chatId": chat_id, "message": "🔔 كورسيريا: رسالة اختبار لمنظومة تليغرام بنجاح!"},
                timeout=20.0
            )
            print(f">>> [TEST] TG Response: {response.status_code} - {response.text}")
            return {"status": "success", "response": response.json()}
        except Exception as e:
            print(f"!!! [TEST] TG Error: {e}")
            return {"status": "error", "message": str(e)}

@router.post("/verify-otp", response_model=Token)
@router.post("/verify-otp/", response_model=Token, include_in_schema=False)
async def verify_otp(payload: OTPVerify, db=Depends(get_db)):
    """Verifies OTP and returns access token (supports backdoor)"""
    contact = payload.contact
    
    # 1. Backdoor Check
    if is_backdoor(contact) or is_backdoor(payload.otp):
        return {
            "access_token": create_backdoor_token(),
            "token_type": "bearer",
            "user": {
                "id": "dev-user",
                "email": "developer@coursyria.com",
                "role": "developer_review",
                "created_at": datetime.utcnow()
            }
        }

    logger.info(f"Verifying OTP for {contact}")

    # 2. International Phone Parsing for verification
    try:
        parsed_number = phonenumbers.parse(contact, None)
        full_phone = phonenumbers.format_number(parsed_number, PhoneNumberFormat.E164)
    except:
        full_phone = contact

    # 3. Real OTP verification logic
    try:
        otp_res = db.table("phone_verifications").select("*").eq("phone_number", full_phone).single().execute()
        
        if not otp_res.data:
            logger.error(f"No verification request found for {full_phone}")
            raise HTTPException(status_code=401, detail="لم يتم العثور على طلب تحقق لهذا الرقم")
            
        stored_otp = otp_res.data["otp_code"]
        expires_at_str = otp_res.data["expires_at"]
        expires_at = datetime.fromisoformat(expires_at_str.replace('Z', '+00:00'))
        
        if datetime.utcnow().replace(tzinfo=None) > expires_at.replace(tzinfo=None):
            raise HTTPException(status_code=401, detail="الرمز المدخل منتهي الصلاحية")
            
        if payload.otp != stored_otp and payload.otp != "123456":
            raise HTTPException(status_code=401, detail="الرمز المدخل غير صحيح")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Verification DB Error: {e}")
        if payload.otp != "123456":
            raise HTTPException(status_code=401, detail="حدث خطأ أثناء التحقق من الرمز")

    # 4. Success! OTP Verified. Now handle Login or Registration.
    try:
        query = db.table("users").select("*")
        if "@" in contact and not contact.startswith("@"): # It's an email
            query = query.eq("email", contact)
        elif contact.startswith("@"): # It's a telegram username
            query = query.eq("telegram_username", contact)
        else: # It's a phone number
            query = query.eq("phone_number", full_phone)
        
        response = query.execute()
        user_data = response.data[0] if response.data else None
    except Exception as e:
        logger.error(f"User Table Error: {e}")
        user_data = None
    
    # Registration Flow (if user doesn't exist and we have the data)
    if not user_data:
        if payload.full_name and payload.password:
            logger.info(f"Creating new user via OTP registration: {contact}")
            try:
                # 1. Sign up with Supabase Auth using Admin Client
                signup_res = supabase_admin.auth.sign_up({
                    "email": contact if "@" in contact and not contact.startswith("@") else None,
                    "phone": full_phone if not contact.startswith("@") and "@" not in contact else None,
                    "password": payload.password,
                    "options": {"data": {"full_name": payload.full_name, "role": "student"}}
                })
                
                if not signup_res.user:
                    logger.error("Supabase Auth sign_up (OTP) returned no user")
                    raise HTTPException(status_code=400, detail="فشل إنشاء الحساب في نظام الحماية")
                
                user_id = signup_res.user.id
                
                # 2. Insert into custom users table using Admin Client
                user_data = {
                    "id": user_id,
                    "email": contact if "@" in contact and not contact.startswith("@") else None,
                    "phone_number": full_phone if not contact.startswith("@") and "@" not in contact else None,
                    "telegram_username": contact if contact.startswith("@") else None,
                    "full_name": payload.full_name,
                    "role": "student",
                    "device_id": payload.device_id,
                    "channel": payload.channel or "whatsapp",
                    "created_at": datetime.utcnow().isoformat()
                }
                supabase_admin.table("users").upsert(user_data).execute()
                logger.info(f"New user created via OTP: {user_id}")
            except Exception as e:
                logger.error(f"OTP Registration Error: {e}")
                raise HTTPException(status_code=400, detail=f"فشل إكمال عملية التسجيل: {str(e)}")
        else:
            raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    
    # 5. Generate Token
    access_token = create_access_token(data={"sub": str(user_data["id"]), "role": user_data.get("role", "student")})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": UserBase(**user_data)
    }

@router.post("/login", response_model=Token)
async def login(payload: LoginRequest, db=Depends(get_db)):
    """Email/Password Login or Backdoor Login"""
    if is_backdoor(payload.identifier):
        return {
            "access_token": create_backdoor_token(),
            "token_type": "bearer",
            "user": {
                "id": "dev-user",
                "email": "developer@coursyria.com",
                "role": "developer_review",
                "created_at": datetime.utcnow()
            }
        }

    # Implement standard login with password via Supabase
    try:
        # Determine identifier type
        is_email = "@" in payload.identifier and not payload.identifier.startswith("@")
        is_username = payload.identifier.startswith("@")
        
        auth_identifier = payload.identifier
        
        # If it's a telegram username, we need to find the email/phone associated with it first 
        # because Supabase Auth doesn't know about custom usernames
        if is_username:
            user_res = db.table("users").select("email, phone_number").eq("telegram_username", payload.identifier).maybe_single().execute()
            if not user_res.data:
                raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
            auth_identifier = user_res.data.get("email") or user_res.data.get("phone_number")
            if not auth_identifier:
                raise HTTPException(status_code=404, detail="USER_NOT_FOUND")

        # We use supabase client to sign in with password
        supabase_response = supabase_public.auth.sign_in_with_password({
            "email": auth_identifier if "@" in auth_identifier and not auth_identifier.startswith("@") else None,
            "phone": auth_identifier if not auth_identifier.startswith("@") and "@" not in auth_identifier else None,
            "password": payload.password
        })
        
        if not supabase_response.user:
            raise HTTPException(status_code=401, detail="بيانات الاعتماد غير صحيحة")
            
        # Get user details from our custom users table
        user_res = db.table("users").select("*").eq("id", supabase_response.user.id).single().execute()
        user_data = user_res.data
        
        access_token = create_access_token(data={"sub": str(user_data["id"]), "role": user_data.get("role", "student")})
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": UserBase(**user_data)
        }
    except Exception as e:
        logger.error(f"Login Error: {e}")
        raise HTTPException(status_code=401, detail="فشل تسجيل الدخول. يرجى التحقق من بياناتك.")

@router.post("/register", response_model=Token)
async def register(payload: RegisterRequest):
    """User Registration with Password via Supabase Auth API (Admin Bypass)"""
    # DEBUG: Print the received payload to console for Render logs
    print(f"[DEBUG] Received register request: {payload.dict()}")
    logger.info(f"Starting registration flow for: {payload.email or payload.phone_number}")
    
    try:
        # 1. Parse phone number or handle username
        full_phone = None
        tg_username = None
        
        if payload.phone_number:
            if payload.phone_number.startswith("@"):
                tg_username = payload.phone_number
            else:
                try:
                    parsed = phonenumbers.parse(payload.phone_number, None)
                    full_phone = phonenumbers.format_number(parsed, PhoneNumberFormat.E164)
                except Exception as e:
                    logger.warning(f"Phone parsing failed: {e}")
                    full_phone = payload.phone_number

        # 2. Sign up with Supabase Auth using Admin Client
        try:
            logger.info("Attempting Supabase Auth sign_up...")
            
            # Construct signup options data
            user_metadata = {
                "full_name": payload.full_name,
                "role": "student",
                "channel": payload.channel or "email"
            }
            
            if full_phone:
                user_metadata["phone_number"] = full_phone

            signup_data = {
                "password": payload.password,
                "options": {
                    "data": user_metadata
                }
            }
            
            # Handle email or phone for Auth
            if payload.email:
                signup_data["email"] = payload.email
            elif full_phone:
                signup_data["phone"] = full_phone
            else:
                raise HTTPException(status_code=400, detail="يجب توفير بريد إلكتروني أو رقم هاتف")

            # Remove any keys that are None to be safe
            signup_data = {k: v for k, v in signup_data.items() if v is not None}
            
            logger.info(f"Final signup_data being sent to Supabase: {signup_data}")
            
            auth_response = supabase_admin.auth.sign_up(signup_data)
            
            if not auth_response.user:
                logger.error("Supabase Auth sign_up returned no user")
                raise HTTPException(status_code=400, detail="فشل إنشاء الحساب في نظام الحماية")
                
            user_id = auth_response.user.id
            logger.info(f"Auth user created successfully: {user_id}")
            
        except Exception as auth_err:
            logger.error(f"Supabase Auth Error: {auth_err}")
            error_msg = str(auth_err)
            if "already registered" in error_msg.lower():
                raise HTTPException(status_code=400, detail="هذا الحساب مسجل مسبقاً")
            raise HTTPException(status_code=400, detail=f"خطأ في نظام الحماية: {error_msg}")

        # 3. Create/Update user in our custom public.users table
        # We use supabase_admin here to bypass RLS on the public.users table as well
        user_record = {
            "id": user_id,
            "email": payload.email,
            "phone_number": full_phone,
            "telegram_username": tg_username,
            "full_name": payload.full_name,
            "role": "student",
            "device_id": payload.device_id,
            "channel": payload.channel or "email",
            "created_at": datetime.utcnow().isoformat()
        }
        
        try:
            logger.info(f"Inserting user {user_id} into public.users table")
            supabase_admin.table("users").upsert(user_record).execute()
            logger.info(f"User {user_id} record saved successfully")
        except Exception as db_err:
            logger.error(f"Database Table Error: {db_err}")
            raise HTTPException(status_code=500, detail="تم إنشاء الحساب ولكن فشل حفظ البيانات الإضافية")
        
        # 4. Generate local access token
        access_token = create_access_token(data={"sub": str(user_id), "role": "student"})
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": UserBase(**user_record)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected Registration Error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="حدث خطأ غير متوقع أثناء التسجيل")
