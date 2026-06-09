import httpx
import asyncio
import time
import json
import random

BASE_URL = "https://coursyria-api.onrender.com"
BACKDOOR_CODE = "@1258998521@"

async def simulate_user(user_id):
    async with httpx.AsyncClient(timeout=30.0) as client:
        print(f"User {user_id} starting...")
        
        # 1. Auth
        resp = await client.post(f"{BASE_URL}/auth/verify-email-otp", json={
            "contact": BACKDOOR_CODE,
            "otp": BACKDOOR_CODE
        })
        if resp.status_code != 200:
            return f"User {user_id} Auth Failed: {resp.status_code}"
        
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        # 2. Parallel Actions
        tasks = [
            client.get(f"{BASE_URL}/courses", headers=headers),
            client.post(f"{BASE_URL}/community/posts", headers=headers, json={"content": f"Concurrent Post from User {user_id}"}),
            client.get(f"{BASE_URL}/wallet/balance", headers=headers)
        ]
        
        responses = await asyncio.gather(*tasks)
        results = [r.status_code for r in responses]
        
        print(f"User {user_id} finished with statuses: {results}")
        return results

async def run_edge_cases():
    results = {}
    async with httpx.AsyncClient(timeout=10.0) as client:
        # 1. Invalid Course ID (404)
        resp = await client.get(f"{BASE_URL}/courses/00000000-0000-0000-0000-000000000000")
        results["Invalid ID 404"] = resp.status_code
        
        # 2. Unauthorized access (401)
        resp = await client.get(f"{BASE_URL}/user/me")
        results["Unauthorized 401"] = resp.status_code
        
        # 3. Forbidden Admin (401 or 403 or 404)
        resp = await client.get(f"{BASE_URL}/admin/users")
        results["Forbidden 401/403/404"] = resp.status_code

        # 4. Long AI Input
        # Get token first
        resp_auth = await client.post(f"{BASE_URL}/auth/verify-email-otp", json={"contact": BACKDOOR_CODE, "otp": BACKDOOR_CODE})
        token = resp_auth.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        
        long_text = "Physics is fun! " * 500 # 8000+ chars
        resp = await client.post(f"{BASE_URL}/ai/chat", headers=headers, json={"message": long_text})
        results["Long AI Input"] = resp.status_code
        
    return results

async def main():
    print("--- CONCURRENCY TEST (3 Users) ---")
    concurrency_results = await asyncio.gather(*[simulate_user(i) for i in range(3)])
    
    print("\n--- EDGE CASES & SECURITY ---")
    edge_results = await run_edge_cases()
    
    final_data = {
        "concurrency": concurrency_results,
        "edge_cases": edge_results
    }
    
    with open("final_stress_test_results.json", "w") as f:
        json.dump(final_data, f, indent=2)
    
    print("\nTests finished. Results in final_stress_test_results.json")

if __name__ == "__main__":
    asyncio.run(main())
