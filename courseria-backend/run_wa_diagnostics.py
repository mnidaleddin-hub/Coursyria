import httpx
import asyncio
import json

BASE_URL = "https://coursyria-api.onrender.com"
UAE_PHONE = "+971504245008"

async def run_diagnostics():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print(f"🔍 Running Direct WA Diagnostics on {BASE_URL}...")
        
        # Test: UAE Number
        resp = await client.post(f"{BASE_URL}/auth/test-wa-direct", json={"phone": UAE_PHONE, "message": "Diagnostic Test"})
        print(f"Status: {resp.status_code}")
        print(f"Result: {json.dumps(resp.json(), indent=2, ensure_ascii=False)}")

if __name__ == "__main__":
    asyncio.run(run_diagnostics())
