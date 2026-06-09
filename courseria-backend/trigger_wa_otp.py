import httpx
import asyncio
import json

BASE_URL = "https://coursyria-api.onrender.com"
PHONE_NUMBER = "+971504245008"

async def send_wa_otp():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print(f"🚀 Requesting WhatsApp OTP for {PHONE_NUMBER} via {BASE_URL}...")
        
        payload = {
            "contact": PHONE_NUMBER,
            "channel": "whatsapp",
            "type": "login" # Try login first
        }
        
        try:
            resp = await client.post(f"{BASE_URL}/auth/send-otp", json=payload)
            print(f"[{resp.status_code}] Response: {resp.text}")
            
            if resp.status_code == 404 and "USER_NOT_FOUND" in resp.text:
                print("🔄 User not found, trying registration OTP...")
                payload["type"] = "register"
                resp = await client.post(f"{BASE_URL}/auth/send-otp", json=payload)
                print(f"[{resp.status_code}] Response: {resp.text}")
            
            return resp.status_code, resp.json()
        except Exception as e:
            print(f"❌ Error: {e}")
            return 500, str(e)

if __name__ == "__main__":
    asyncio.run(send_wa_otp())
