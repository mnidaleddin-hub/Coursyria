import httpx
import asyncio
import time
import json
import uuid
from datetime import datetime

# LIVE SERVER URL
BASE_URL = "https://coursyria-api.onrender.com"
BACKDOOR_CODE = "@1258998521@"

async def run_live_audit():
    results = []
    
    async with httpx.AsyncClient(timeout=60.0) as client:
        print(f"Starting Courseria LIVE Backend Audit on {BASE_URL}...")

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

        # 0. Health Check
        res, _ = await test_endpoint("Health Check", "GET", "/health")
        results.append(res)
        if not res["success"]:
            print("Health check failed, live server might not be up yet.")

        # 1. Backdoor Authentication
        res, resp = await test_endpoint("Authentication", "POST", "/auth/verify-email-otp", {
            "contact": BACKDOOR_CODE,
            "otp": BACKDOOR_CODE
        })
        results.append(res)
        if not res["success"]:
            print("Auth failed on live server.")
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
        res, resp_post = await test_endpoint("Create Post", "POST", "/community/posts", {"content": "Live Audit Test Post"}, headers=headers)
        results.append(res)
        post_id = resp_post.json()["id"] if res["success"] else None

        # 6. Fetch Community Posts
        res, _ = await test_endpoint("Fetch Posts", "GET", "/community/posts", headers=headers)
        results.append(res)

        # 7. Add Comment
        if post_id:
            res, _ = await test_endpoint("Add Comment", "POST", f"/community/posts/{post_id}/comments", {"content": "Live Audit Test Comment"}, headers=headers)
            results.append(res)
        else:
            results.append({"name": "Add Comment", "success": False, "status": "N/A", "duration": 0, "response": "No post found"})

        # 8. Get Wallet Balance
        res, _ = await test_endpoint("Wallet Balance", "GET", "/wallet/balance", headers=headers)
        results.append(res)

        # 9. Use Promo Code
        res, _ = await test_endpoint("Use Promo Code", "POST", "/wallet/use-promo-code", {"code": "INVALID-CODE"}, headers=headers)
        results.append(res)

        # 10. AI Chat
        res, _ = await test_endpoint("AI Chat", "POST", "/ai/chat", {"message": "ما هو قانون نيوتن الثاني؟"}, headers=headers)
        results.append(res)

        # 11. AI Summarize
        long_text = "الفيزياء هي العلم الذي يدرس المادة والطاقة والتفاعلات بينهما. قوانين نيوتن للحركة هي ثلاثة قوانين فيزيائية أسست ميكانيكا الكم. يصف القانون الأول لنيوتن الجسم الساكن بأنه يبقى ساكناً ما لم تؤثر عليه قوة خارجية. القانون الثاني ينص على أن تسارع الجسم يتناسب طردياً مع القوة المؤثرة عليه. القانون الثالث ينص على أن لكل فعل رد فعل مساوٍ له في المقدار ومعاكس له في الاتجاه." * 20
        res, _ = await test_endpoint("AI Summarize", "POST", "/ai/summarize", {"content": long_text}, headers=headers)
        results.append(res)

        # 12. Generate Mock Exam
        res, resp_exam = await test_endpoint("Generate Mock", "GET", "/exams/generate-mock", {"grade": "bac_scientific", "subject": "physics"}, headers=headers)
        results.append(res)

        # 13. AI Generate Quiz
        res, _ = await test_endpoint("AI Generate Quiz", "POST", "/ai/generate-quiz", {"content": "موضوع عن الخلايا النباتية والحيوانية"}, headers=headers)
        results.append(res)

        # 14. AI Explain Like I'm 5
        res, _ = await test_endpoint("AI Explain Simple", "POST", "/ai/explain-like-im-5", {"content": "النسبية العامة لآينشتاين"}, headers=headers)
        results.append(res)

        # 15. AI Flashcards
        res, _ = await test_endpoint("AI Flashcards", "POST", "/ai/flashcards", {"content": "درس عن الحرب العالمية الثانية"}, headers=headers)
        results.append(res)

        # 16. AI Grammar Corrector
        res, _ = await test_endpoint("AI Grammar", "POST", "/ai/grammar-corrector", {"text": "انا اكلت التفاحة في الصباح الباكر لاكنها كانت مرة."}, headers=headers)
        results.append(res)

        # 17. Chat Rooms
        res, _ = await test_endpoint("Chat Rooms", "GET", "/chat/rooms", headers=headers)
        results.append(res)

        # Save results
        with open("live_audit_results.json", "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print("\nLive Audit completed. Results saved to live_audit_results.json")

if __name__ == "__main__":
    asyncio.run(run_live_audit())
