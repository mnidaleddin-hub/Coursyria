import httpx
import asyncio
import time
import json
import uuid
from datetime import datetime

BASE_URL = "http://localhost:8000"
BACKDOOR_CODE = "@1258998521@"

async def run_audit():
    results = []
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        print("Starting Courseria Backend Audit...")

        # --- Helper for logging ---
        async def test_endpoint(name, method, path, data=None, headers=None, files=None):
            start = time.time()
            try:
                if method == "GET":
                    resp = await client.get(f"{BASE_URL}{path}", headers=headers, params=data)
                elif method == "POST":
                    resp = await client.post(f"{BASE_URL}{path}", headers=headers, json=data, files=files)
                elif method == "PUT":
                    resp = await client.put(f"{BASE_URL}{path}", headers=headers, json=data)
                elif method == "DELETE":
                    resp = await client.delete(f"{BASE_URL}{path}", headers=headers)
                
                duration = (time.time() - start) * 1000
                res = {
                    "name": name,
                    "method": method,
                    "path": path,
                    "status": resp.status_code,
                    "duration": duration,
                    "response": resp.text[:500] + "..." if len(resp.text) > 500 else resp.text,
                    "success": resp.status_code in [200, 201, 204]
                }
                print(f"[{resp.status_code}] {name} - {duration:.2f}ms")
                return res, resp
            except Exception as e:
                duration = (time.time() - start) * 1000
                print(f"[ERR] {name} - {e}")
                return {
                    "name": name,
                    "method": method,
                    "path": path,
                    "status": 500,
                    "duration": duration,
                    "response": str(e),
                    "success": False
                }, None

        # 1. Backdoor Authentication
        res, resp = await test_endpoint("Authentication", "POST", "/auth/verify-email-otp", {
            "contact": BACKDOOR_CODE,
            "otp": BACKDOOR_CODE
        })
        results.append(res)
        if not res["success"]:
            print("Auth failed, stopping audit.")
            return
        
        token = resp.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        user_id = resp.json()["user"]["id"]

        # 2. Get Profile
        res, _ = await test_endpoint("Get Profile", "GET", "/user/me", headers=headers)
        results.append(res)

        # 3. Fetch Courses
        res, resp_courses = await test_endpoint("Fetch Courses", "GET", "/courses", headers=headers)
        results.append(res)
        course_id = None
        if res["success"] and resp_courses.json():
            course_id = resp_courses.json()[0]["id"]

        # 4. Fetch Course Details
        if course_id:
            res, _ = await test_endpoint("Course Details", "GET", f"/courses/{course_id}", headers=headers)
            results.append(res)
        else:
            results.append({"name": "Course Details", "success": False, "status": "N/A", "duration": 0, "response": "No course found"})

        # 5. Create Post
        res, resp_post = await test_endpoint("Create Post", "POST", "/community/posts", {"content": "Audit Test Post"}, headers=headers)
        results.append(res)
        post_id = resp_post.json()["id"] if res["success"] else None

        # 6. Fetch Community Posts
        res, _ = await test_endpoint("Fetch Posts", "GET", "/community/posts", headers=headers)
        results.append(res)

        # 7. Add Comment
        if post_id:
            res, _ = await test_endpoint("Add Comment", "POST", f"/community/posts/{post_id}/comments", {"content": "Audit Test Comment"}, headers=headers)
            results.append(res)
        else:
            results.append({"name": "Add Comment", "success": False, "status": "N/A", "duration": 0, "response": "No post found"})

        # 8. Get Wallet Balance
        res, _ = await test_endpoint("Wallet Balance", "GET", "/wallet/balance", headers=headers)
        results.append(res)

        # 9. Use Promo Code (Expected to fail if code doesn't exist)
        res, _ = await test_endpoint("Use Promo Code", "POST", "/wallet/use-promo-code", {"code": "INVALID-CODE"}, headers=headers)
        results.append(res)

        # 10. AI Chat
        res, _ = await test_endpoint("AI Chat", "POST", "/ai/chat", {"message": "Hello AI"}, headers=headers)
        results.append(res)

        # 11. AI Summarize
        res, _ = await test_endpoint("AI Summarize", "POST", "/ai/summarize", {"content": "Quantum physics is cool."}, headers=headers)
        results.append(res)

        # 12. Generate Mock Exam
        res, resp_exam = await test_endpoint("Generate Mock", "GET", "/exams/generate-mock", {"grade": "bac_scientific", "subject": "physics"}, headers=headers)
        results.append(res)

        # 13. Get User Stats
        res, _ = await test_endpoint("User Stats", "GET", "/user/stats", headers=headers)
        results.append(res)

        # 14. Update Profile
        res, _ = await test_endpoint("Update Profile", "PUT", "/user/me", {"full_name": "Auditor User"}, headers=headers)
        results.append(res)

        # 15. Chat Rooms
        res, _ = await test_endpoint("Chat Rooms", "GET", "/chat/rooms", headers=headers)
        results.append(res)

        # Save results
        with open("audit_results.json", "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print("\nAudit completed. Results saved to audit_results.json")

if __name__ == "__main__":
    asyncio.run(run_audit())
