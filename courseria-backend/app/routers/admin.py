from fastapi import APIRouter, HTTPException, Depends, status
from app.database import get_db
from app.dependencies import get_current_user
from typing import List
import datetime

router = APIRouter()

import secrets
import string

# Guard for Admin access (Strict Supabase metadata check)
def verify_admin(user=Depends(get_current_user)):
    # Verify if user has is_admin: true in Supabase metadata/role
    if not user.get("is_admin") and user.get("email") not in ["admin@coursyria.com"]:
        raise HTTPException(status_code=403, detail="غير مصرح لك بالوصول لهذه المنطقة الإدارية")
    return user

@router.post("/team-application")
@router.post("/team-application/", include_in_schema=False)
async def submit_team_application(full_name: str, specialization: str, city: str, bio: str, user=Depends(get_current_user), db=Depends(get_db)):
    """Submit an application to join the Courseria team"""
    try:
        data = {
            "user_id": user["sub"],
            "full_name": full_name,
            "specialization": specialization,
            "city": city,
            "bio": bio,
            "status": "pending",
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        db.table("team_applications").insert(data).execute()
        return {"status": "success", "message": "تم استلام طلب انضمامك بنجاح، سنتواصل معك قريباً"}
    except Exception as e:
        print(f"!!! Team App Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إرسال طلب الانضمام")

@router.post("/transactions/{tx_id}/approve")
async def approve_transaction(tx_id: str, admin=Depends(verify_admin), db=Depends(get_db)):
    """Approve payment receipt and update student balance"""
    try:
        # 1. Get Transaction
        tx_res = db.table("wallet_transactions").select("*").eq("id", tx_id).single().execute()
        if not tx_res.data:
            raise HTTPException(status_code=404, detail="المعاملة غير موجودة")
        
        tx = tx_res.data
        if tx["status"] != "pending":
            raise HTTPException(status_code=400, detail="هذه المعاملة تمت معالجتها مسبقاً")

        # 2. Update Wallet Balance
        wallet_res = db.table("wallets").select("balance").eq("user_id", tx["user_id"]).single().execute()
        current_balance = wallet_res.data["balance"] if wallet_res.data else 0
        new_balance = current_balance + tx["amount"]

        db.table("wallets").upsert({
            "user_id": tx["user_id"],
            "balance": new_balance,
            "updated_at": datetime.datetime.utcnow().isoformat()
        }).execute()

        # 3. Update Transaction Status
        db.table("wallet_transactions").update({
            "status": "approved",
            "processed_at": datetime.datetime.utcnow().isoformat(),
            "processed_by": admin["sub"]
        }).eq("id", tx_id).execute()

        return {"status": "success", "message": "تمت الموافقة وشحن الرصيد بنجاح"}
    except Exception as e:
        print(f"!!! Admin Approve Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إتمام الموافقة")

@router.post("/charity-requests/{req_id}/grant")
async def grant_charity_course(req_id: str, course_id: str, admin=Depends(verify_admin), db=Depends(get_db)):
    """Grant a free course to a student as charity"""
    try:
        req_res = db.table("charity_requests").select("*").eq("id", req_id).single().execute()
        if not req_res.data:
            raise HTTPException(status_code=404, detail="الطلب غير موجود")
        
        user_id = req_res.data["user_id"]

        # Add Subscription
        db.table("subscriptions").insert({
            "user_id": user_id,
            "course_id": course_id,
            "is_charity": True,
            "purchased_at": datetime.datetime.utcnow().isoformat()
        }).execute()

        # Update Request Status
        db.table("charity_requests").update({
            "status": "granted",
            "granted_at": datetime.datetime.utcnow().isoformat()
        }).eq("id", req_id).execute()

        return {"status": "success", "message": "تم منح الكورس للطالب كصدقة"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في منح الكورس")

@router.post("/promo-codes/generate")
async def generate_promo_codes(amount: float, count: int = 1, admin=Depends(verify_admin), db=Depends(get_db)):
    """Generate unique activation codes for physical sale"""
    try:
        codes = []
        for _ in range(count):
            code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(12))
            code_data = {
                "code": code,
                "credit_value": amount,
                "is_used": False,
                "created_at": datetime.datetime.utcnow().isoformat(),
                "created_by": admin["sub"]
            }
            db.table("promo_codes").insert(code_data).execute()
            codes.append(code)
        
        return {"status": "success", "codes": codes}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في توليد الأكواد")

@router.post("/support/respond/{ticket_id}")
async def respond_to_support(ticket_id: str, response_text: str, admin=Depends(verify_admin), db=Depends(get_db)):
    """Respond to a student support/complaint ticket"""
    try:
        db.table("support_tickets").update({
            "response": response_text,
            "status": "resolved",
            "resolved_at": datetime.datetime.utcnow().isoformat()
        }).eq("id", ticket_id).execute()
        return {"status": "success", "message": "تم إرسال الرد بنجاح"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في تحديث تذكرة الدعم")
