from fastapi import APIRouter, HTTPException, Depends, status
from app.models.wallet_schemas import WalletRechargeRequest, WalletRechargeResponse, WalletBalanceResponse, DepositReceiptRequest, WalletTransactionBase
from app.dependencies import get_current_user, get_supabase_client
import uuid
import datetime
import logging

logger = logging.getLogger("courseria.wallet")

router = APIRouter()

@router.post("/deposit-receipt")
@router.post("/deposit-receipt/", include_in_schema=False)
async def deposit_receipt(payload: DepositReceiptRequest, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """Submit a payment receipt for manual admin approval"""
    try:
        tx_id = str(uuid.uuid4())
        data = {
            "id": tx_id,
            "user_id": user["user_id"],
            "transaction_id": payload.transaction_id,
            "amount": payload.amount,
            "payment_method": payload.payment_method,
            "receipt_screenshot_url": payload.receipt_screenshot_url,
            "note": payload.note,
            "status": "pending",
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        db.table("wallet_transactions").insert(data).execute()
        return {"status": "success", "message": "تم استلام إيصال الدفع بنجاح، بانتظار مراجعة الإدارة"}
    except Exception as e:
        print(f"!!! Deposit Receipt Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إرسال إيصال الدفع")

@router.post("/charity-request")
@router.post("/charity-request/", include_in_schema=False)
async def submit_charity_request(justification: str, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """Submit a request for a free course for financial reasons"""
    try:
        data = {
            "user_id": user["user_id"],
            "justification": justification,
            "status": "pending",
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        db.table("charity_requests").insert(data).execute()
        return {"status": "success", "message": "تم إرسال طلبك بنجاح، سيتم مراجعته من قبل الإدارة"}
    except Exception as e:
        print(f"!!! Charity Request Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إرسال طلب الصدقة")

@router.post("/support-ticket")
@router.post("/support-ticket/", include_in_schema=False)
async def submit_support_ticket(title: str, message: str, category: str = "general", user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """Submit a support/complaint ticket"""
    try:
        data = {
            "user_id": user["user_id"],
            "title": title,
            "message": message,
            "category": category,
            "status": "open",
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        db.table("support_tickets").insert(data).execute()
        return {"status": "success", "message": "تم إرسال تذكرتك بنجاح، فريق الدعم سيقوم بالرد قريباً"}
    except Exception as e:
        print(f"!!! Support Ticket Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إرسال تذكرة الدعم")

@router.get("/transactions", response_model=List[WalletTransactionBase])
async def get_transactions(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    """جلب سجل المعاملات للمستخدم الحالي"""
    try:
        response = db.table("wallet_transactions").select("*").eq("user_id", user["user_id"]).order("created_at", desc=True).execute()
        return response.data
    except Exception as e:
        logger.error(f"!!! Fetch Transactions Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في جلب سجل المعاملات")

@router.get("/balance", response_model=WalletBalanceResponse)
@router.get("/balance/", response_model=WalletBalanceResponse, include_in_schema=False)
async def get_balance(user=Depends(get_current_user), db=Depends(get_supabase_client)):
    try:
        response = db.table("wallets").select("balance").eq("user_id", user["user_id"]).maybe_single().execute()
        if response.data:
            return {"balance": response.data["balance"]}
        
        # If no wallet found, initialize one
        new_wallet = {
            "user_id": user["user_id"],
            "balance": 0,
            "updated_at": datetime.datetime.utcnow().isoformat()
        }
        db.table("wallets").insert(new_wallet).execute()
        return {"balance": 0}
    except Exception as e:
        print(f"!!! Wallet Balance Error: {e}")
        raise HTTPException(status_code=500, detail="خطأ في جلب رصيد المحفظة")

@router.post("/recharge", response_model=WalletRechargeResponse)
@router.post("/recharge/", response_model=WalletRechargeResponse, include_in_schema=False)
async def recharge_wallet(payload: WalletRechargeRequest, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    try:
        # 1. Create a wallet request for admin approval
        request_id = str(uuid.uuid4())
        request_data = {
            "id": request_id,
            "user_id": user["user_id"],
            "amount": payload.amount,
            "payment_method": payload.payment_method,
            "transaction_id": payload.transaction_id,
            "receipt_screenshot_url": payload.receipt_screenshot_url,
            "note": payload.note,
            "status": "pending",
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        
        db.table("wallet_requests").insert(request_data).execute()
        
        return {
            "id": request_id,
            "status": "pending",
            "message": "تم إرسال طلب الشحن بنجاح. بانتظار موافقة الإدارة."
        }
    except Exception as e:
        print(f"!!! Wallet Recharge Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إرسال طلب الشحن")

@router.post("/purchase/{course_id}")
async def purchase_course(course_id: str, user=Depends(get_current_user), db=Depends(get_supabase_client)):
    try:
        # 1. Get Course Price
        course_res = db.table("courses").select("price, title").eq("id", course_id).maybe_single().execute()
        if not course_res.data:
            raise HTTPException(status_code=404, detail="الكورس غير موجود")
        
        price = course_res.data["price"]
        course_title = course_res.data["title"]
        
        # 2. Check Wallet Balance
        wallet_res = db.table("wallets").select("balance").eq("user_id", user["user_id"]).maybe_single().execute()
        if not wallet_res.data or wallet_res.data["balance"] < price:
            raise HTTPException(status_code=400, detail="رصيدك غير كافٍ لشراء هذا الكورس")
        
        # 3. Deduct Balance & Create Subscription (Transactionally if possible in Supabase, here we do sequential)
        new_balance = wallet_res.data["balance"] - price
        db.table("wallets").update({"balance": new_balance, "updated_at": datetime.datetime.utcnow().isoformat()}).eq("user_id", user["user_id"]).execute()
        
        # 4. Create Subscription record
        sub_data = {
            "user_id": user["user_id"],
            "course_id": course_id,
            "purchased_at": datetime.datetime.utcnow().isoformat()
        }
        db.table("subscriptions").insert(sub_data).execute()
        
        return {
            "status": "success",
            "message": f"تم شراء كورس {course_title} بنجاح",
            "new_balance": new_balance
        }
    except HTTPException as he:
        raise he
    except Exception as e:
        print(f"!!! Course Purchase Error: {e}")
        raise HTTPException(status_code=500, detail="فشل في إتمام عملية الشراء")
