from fastapi import APIRouter, HTTPException, Depends, status
from app.database import get_db_admin
from app.dependencies import get_current_user
from typing import List
import datetime
import secrets
import string

router = APIRouter()

# حارس للوصول الإداري (يتحقق من الدور في التوكن)
def verify_admin(user=Depends(get_current_user)):
    if user.get("role") != "admin" and user.get("email") not in ["admin@coursyria.com"]:
        raise HTTPException(status_code=403, detail="غير مصرح لك بالوصول لهذه المنطقة الإدارية")
    return user

@router.post("/transactions/{tx_id}/approve")
async def approve_transaction(tx_id: str, admin=Depends(verify_admin), db=Depends(get_db_admin)):
    """الموافقة على معاملة (نظام التدقيق المزدوج)"""
    try:
        # 1. جلب المعاملة
        tx_res = db.table("wallet_transactions").select("*").eq("id", tx_id).single().execute()
        if not tx_res.data:
            raise HTTPException(status_code=404, detail="المعاملة غير موجودة")
        
        tx = tx_res.data
        if tx["status"] == "approved":
            raise HTTPException(status_code=400, detail="هذه المعاملة تمت الموافقة عليها مسبقاً")

        # التحقق من المدققين
        auditor1 = tx.get("audited_by_1")
        auditor2 = tx.get("audited_by_2")

        if not auditor1:
            # أول تدقيق
            db.table("wallet_transactions").update({
                "audited_by_1": admin["user_id"],
                "audited_at_1": datetime.datetime.utcnow().isoformat(),
                "status": "pending_second_audit"
            }).eq("id", tx_id).execute()
            return {"status": "success", "message": "تم التدقيق الأول، بانتظار مدقق ثانٍ"}
        
        if auditor1 == admin["user_id"]:
            raise HTTPException(status_code=400, detail="لا يمكن لنفس المدقق الموافقة مرتين")

        if not auditor2:
            # التدقيق الثاني والنهائي
            # 2. تحديث الرصيد
            wallet_res = db.table("wallets").select("balance").eq("user_id", tx["user_id"]).maybe_single().execute()
            current_balance = wallet_res.data["balance"] if wallet_res.data else 0
            new_balance = current_balance + tx["amount"]

            db.table("wallets").upsert({
                "user_id": tx["user_id"],
                "balance": new_balance,
                "updated_at": datetime.datetime.utcnow().isoformat()
            }).execute()

            # 3. تحديث حالة المعاملة
            db.table("wallet_transactions").update({
                "audited_by_2": admin["user_id"],
                "audited_at_2": datetime.datetime.utcnow().isoformat(),
                "status": "approved",
                "processed_at": datetime.datetime.utcnow().isoformat(),
                "processed_by": admin["user_id"]
            }).eq("id", tx_id).execute()

            # 4. توزيع الأجور آلياً (محاكاة)
            await distribute_shares(tx["amount"], tx["user_id"], db)

            return {"status": "success", "message": "تمت الموافقة النهائية وشحن الرصيد بنجاح"}

        return {"status": "error", "message": "المعاملة مكتملة بالفعل"}
    except Exception as e:
        print(f"!!! Admin Approve Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إتمام الموافقة")

async def distribute_shares(amount: float, student_id: str, db):
    """توزيع الأجور آلياً للمعلمين والمساهمين"""
    # مثال: 60% للمعلم، 20% للمنصة، 10% للتسويق، 10% صيانة
    try:
        # هذه الوظيفة تفترض وجود جدول share_distributions
        db.table("share_distributions").insert({
            "amount": amount,
            "teacher_share": amount * 0.6,
            "platform_share": amount * 0.2,
            "marketing_share": amount * 0.1,
            "maintenance_share": amount * 0.1,
            "created_at": datetime.datetime.utcnow().isoformat()
        }).execute()
    except Exception as e:
        print(f"Share Distribution Log Error: {e}")

@router.get("/reports/daily")
async def get_daily_report(admin=Depends(verify_admin), db=Depends(get_db_admin)):
    """تقرير مالي يومي آلي"""
    try:
        today = datetime.date.today().isoformat()
        tx_res = db.table("wallet_transactions").select("*").gte("created_at", today).execute()
        
        total_recharged = sum(tx["amount"] for tx in tx_res.data if tx["status"] == "approved")
        pending_count = sum(1 for tx in tx_res.data if tx["status"] != "approved")
        
        return {
            "date": today,
            "total_recharged": total_recharged,
            "pending_transactions": pending_count,
            "transactions": tx_res.data
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في توليد التقرير")

@router.post("/content/audit/{lesson_id}")
async def audit_content(lesson_id: str, is_approved: bool, admin=Depends(verify_admin), db=Depends(get_db_admin)):
    """لوحة تدقيق المحتوى قبل النشر"""
    try:
        status = "published" if is_approved else "rejected"
        db.table("lessons").update({
            "status": status,
            "audited_by": admin["user_id"],
            "audited_at": datetime.datetime.utcnow().isoformat()
        }).eq("id", lesson_id).execute()
        return {"status": "success", "message": f"تم تحديث حالة الدرس إلى {status}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في تدقيق المحتوى")

@router.post("/charity-requests/{req_id}/grant")
async def grant_charity_course(req_id: str, course_id: str, admin=Depends(verify_admin), db=Depends(get_db_admin)):
    """منح كورس مجاني لطالب (صدقة)"""
    try:
        req_res = db.table("charity_requests").select("*").eq("id", req_id).single().execute()
        if not req_res.data:
            raise HTTPException(status_code=404, detail="الطلب غير موجود")
        
        user_id = req_res.data["user_id"]

        # إضافة اشتراك
        db.table("subscriptions").insert({
            "user_id": user_id,
            "course_id": course_id,
            "is_charity": True,
            "purchased_at": datetime.datetime.utcnow().isoformat()
        }).execute()

        # تحديث حالة الطلب
        db.table("charity_requests").update({
            "status": "granted",
            "granted_at": datetime.datetime.utcnow().isoformat()
        }).eq("id", req_id).execute()

        return {"status": "success", "message": "تم منح الكورس للطالب بنجاح"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في منح الكورس")

@router.post("/promo-codes/generate")
async def generate_promo_codes(amount: float, count: int = 1, admin=Depends(verify_admin), db=Depends(get_db_admin)):
    """توليد أكواد تفعيل للشحن اليدوي"""
    try:
        codes = []
        for _ in range(count):
            code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(12))
            code_data = {
                "code": code,
                "credit_value": amount,
                "is_used": False,
                "created_at": datetime.datetime.utcnow().isoformat(),
                "created_by": admin["user_id"]
            }
            db.table("promo_codes").insert(code_data).execute()
            codes.append(code)
        
        return {"status": "success", "codes": codes}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في توليد الأكواد")

@router.post("/support/respond/{ticket_id}")
async def respond_to_support(ticket_id: str, response_text: str, admin=Depends(verify_admin), db=Depends(get_db_admin)):
    """الرد على تذكرة دعم فني"""
    try:
        db.table("support_tickets").update({
            "response": response_text,
            "status": "resolved",
            "resolved_at": datetime.datetime.utcnow().isoformat()
        }).eq("id", ticket_id).execute()
        return {"status": "success", "message": "تم إرسال الرد بنجاح"}
    except Exception as e:
        raise HTTPException(status_code=500, detail="فشل في تحديث تذكرة الدعم")
