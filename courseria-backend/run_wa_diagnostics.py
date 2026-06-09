import httpx
import asyncio
import json

BASE_URL = "https://coursyria-api.onrender.com"
UAE_PHONE = "+971504245008"
SYR_PHONE = "+963930111876"

async def run_diagnostics():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print(f"🔍 Running Direct WA Diagnostics on {BASE_URL}...")
        
        # Test 1: UAE Number
        print(f"\n1. Testing UAE Number: {UAE_PHONE}")
        resp1 = await client.post(f"{BASE_URL}/auth/test-wa-direct", json={"phone": UAE_PHONE, "message": "Diagnostic Test: UAE"})
        print(f"Status: {resp1.status_code}")
        print(f"Result: {json.dumps(resp1.json(), indent=2, ensure_ascii=False)}")
        
        # Test 2: Syrian Number
        print(f"\n2. Testing Syrian Number: {SYR_PHONE}")
        resp2 = await client.post(f"{BASE_URL}/auth/test-wa-direct", json={"phone": SYR_PHONE, "message": "Diagnostic Test: SYRIA"})
        print(f"Status: {resp2.status_code}")
        print(f"Result: {json.dumps(resp2.json(), indent=2, ensure_ascii=False)}")

if __name__ == "__main__":
    asyncio.run(run_diagnostics())
