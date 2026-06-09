import httpx
import asyncio
import json
import time

BASE_URL = "http://localhost:8000"
# This token should be generated using the BACKDOOR_SECRET and algorithms used in app.auth_utils
# For the purpose of this script, we'll assume we can get one via /auth/verify-email-otp with backdoor code
BACKDOOR_CODE = "@1258998521@"

async def run_mvp_test():
    async with httpx.AsyncClient(timeout=30.0) as client:
        print("\nStarting MVP Integration Test...")
        
        # Scenario 1: Health Check
        print("Scenario 1: Testing Health Check...")
        r1 = await client.get(f"{BASE_URL}/health")
        # print(f"Health Response: {r1.status_code} - {r1.text}") # Removed to avoid encoding issues
        assert r1.status_code == 200
        assert r1.json()["status"] == "ok"
        print("Health Check Passed")

        # Scenario 2: Backdoor Authentication
        print("Scenario 2: Testing Backdoor Authentication...")
        r2 = await client.post(f"{BASE_URL}/auth/verify-email-otp", json={
            "contact": BACKDOOR_CODE,
            "otp": BACKDOOR_CODE
        })
        assert r2.status_code == 200
        token = r2.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        print("Backdoor Auth Passed")

        # Scenario 3: Fetch Courses (Protected)
        print("Scenario 3: Fetching Courses...")
        r3 = await client.get(f"{BASE_URL}/courses", headers=headers)
        if r3.status_code != 200:
            print(f"FAILED: /courses returned {r3.status_code}")
        assert r3.status_code == 200
        print(f"Fetch Courses Passed")

        # Scenario 4: Community Post
        print("Scenario 4: Creating Community Post...")
        r4 = await client.post(f"{BASE_URL}/community/posts", headers=headers, json={
            "content": "MVP Integration Test Post"
        })
        if r4.status_code == 201:
            print("Community Post Created")
        else:
            print(f"Community Post status: {r4.status_code}")

        # Scenario 5: AI Summarization
        print("Scenario 5: Testing AI Summarization...")
        r5 = await client.post(f"{BASE_URL}/ai/summarize", headers=headers, json={
            "content": "Physics is the study of matter and energy."
        })
        assert r5.status_code == 200
        assert "summary" in r5.json()
        print("AI Summarization Passed")

        print("\nMVP Integration Test Completed!")

if __name__ == "__main__":
    asyncio.run(run_mvp_test())
