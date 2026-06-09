import httpx
import asyncio
import json

BASE_URL = "https://coursyria-api.onrender.com"
UAE_PHONE = "+971504245008"
ID_INSTANCE = "7107621915"
TOKEN = "671698dabcf043ed84bc4726b52d242f6035b4f0cc3b4a4f81"

async def run_diagnostics():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print(f"🔍 Running Direct WA Diagnostics on {BASE_URL} with MANUAL CREDENTIALS...")
        
        # Test: UAE Number with manual credentials
        payload = {
            "phone": UAE_PHONE, 
            "message": "Diagnostic Test: Manual Credentials",
            "id_instance": ID_INSTANCE,
            "token": TOKEN
        }
        resp = await client.post(f"{BASE_URL}/auth/test-wa-direct", json=payload)
        print(f"Status: {resp.status_code}")
        print(f"Result: {json.dumps(resp.json(), indent=2, ensure_ascii=False)}")

if __name__ == "__main__":
    asyncio.run(run_diagnostics())
