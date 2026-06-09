import httpx
import asyncio
import time
import json
from datetime import datetime

BASE_URL = "https://coursyria-api.onrender.com"
BACKDOOR_CODE = "@1258998521@"

async def run_comprehensive_audit():
    results = []
    headers = {}
    context_data = {}

    async with httpx.AsyncClient(timeout=60.0) as client:
        print(f"🚀 Starting Courseria E2E User Journey Audit on {BASE_URL}...")

        async def test_step(name, method, path, data=None, params=None):
            start = time.time()
            try:
                if method == "GET":
                    resp = await client.get(f"{BASE_URL}{path}", headers=headers, params=params)
                elif method == "POST":
                    resp = await client.post(f"{BASE_URL}{path}", headers=headers, json=data)
                elif method == "PUT":
                    resp = await client.put(f"{BASE_URL}{path}", headers=headers, json=data)
                
                duration = (time.time() - start) * 1000
                success = resp.status_code in [200, 201, 204]
                
                res = {
                    "name": name,
                    "status": resp.status_code,
                    "duration": duration,
                    "success": success,
                    "response": resp.json() if success and resp.text else resp.text
                }
                print(f"[{resp.status_code}] {name} - {duration:.2f}ms")
                return res, resp
            except Exception as e:
                duration = (time.time() - start) * 1000
                print(f"[ERR] {name} - {e}")
                return {
                    "name": name,
                    "status": 500,
                    "duration": duration,
                    "success": False,
                    "response": str(e)
                }, None

        # 1. Health Check
        res, _ = await test_step("Health Check", "GET", "/health")
        results.append(res)

        # 2. Authentication
        res, resp = await test_step("Authentication", "POST", "/auth/verify-email-otp", {
            "contact": BACKDOOR_CODE,
            "otp": BACKDOOR_CODE
        })
        results.append(res)
        if not res["success"]:
            print("❌ Auth failed, stopping journey.")
            return
        
        token = resp.json()["access_token"]
        headers["Authorization"] = f"Bearer {token}"

        # 3. Get Profile
        res, resp = await test_step("Get Profile", "GET", "/user/me")
        results.append(res)

        # 4. Fetch Courses
        res, resp = await test_step("Fetch Courses", "GET", "/courses")
        results.append(res)
        if res["success"] and resp.json():
            context_data["course_id"] = resp.json()[0]["id"]

        # 5. Course Details
        if "course_id" in context_data:
            res, _ = await test_step("Course Details", "GET", f"/courses/{context_data['course_id']}")
            results.append(res)
        else:
            results.append({"name": "Course Details", "success": False, "status": "N/A", "duration": 0, "response": "No course found"})

        # 6. Create Post
        res, resp = await test_step("Create Post", "POST", "/community/posts", {
            "content": "هذا اختبار شامل للمجتمع – هل يعمل التطبيق بكفاءة؟"
        })
        results.append(res)
        if res["success"]:
            context_data["post_id"] = resp.json()["id"]

        # 7. Fetch Posts
        res, _ = await test_step("Fetch Posts", "GET", "/community/posts")
        results.append(res)

        # 8. Add Comment
        if "post_id" in context_data:
            res, _ = await test_step("Add Comment", "POST", f"/community/posts/{context_data['post_id']}/comments", {
                "content": "تعليق تجريبي من المستخدم الآلي."
            })
            results.append(res)
        else:
            results.append({"name": "Add Comment", "success": False, "status": "N/A", "duration": 0, "response": "No post found"})

        # 9. Wallet Balance
        res, _ = await test_step("Wallet Balance", "GET", "/wallet/balance")
        results.append(res)

        # 10. Use Promo Code
        res, _ = await test_step("Use Promo Code", "POST", "/wallet/use-promo-code", {"code": "TEST2025"})
        results.append(res)

        # 11. AI Tests
        print("🤖 Testing AI Services (Real API)...")
        
        # 11.1 Chat
        res, _ = await test_step("AI Chat", "POST", "/ai/chat", {"message": "اشرح قانون نيوتن الثاني ببساطة"})
        results.append(res)

        # 11.2 Summarize
        long_text = "النظرية النسبية هي من أشهر نظريات الفيزياء الحديثة التي طورها ألبرت أينشتاين. تنقسم إلى النسبية الخاصة والنسبية العامة. تغيرت نظرتنا للزمان والمكان والجاذبية بشكل كامل بفضل هذه النظرية." * 20
        res, _ = await test_step("AI Summarize", "POST", "/ai/summarize", {"content": long_text})
        results.append(res)

        # 11.3 Generate Quiz
        res, _ = await test_step("AI Generate Quiz", "POST", "/ai/generate-quiz", {"content": "مقدمة في الكيمياء العضوية"})
        results.append(res)

        # 11.4 Explain Simple
        res, _ = await test_step("AI Explain Simple", "POST", "/ai/explain-like-im-5", {"content": "تفسير معادلات ماكسويل"})
        results.append(res)

        # 11.5 Flashcards
        res, _ = await test_step("AI Flashcards", "POST", "/ai/flashcards", {"content": "أهم 5 قوانين في الفيزياء"})
        results.append(res)

        # 11.6 Grammar
        res, _ = await test_step("AI Grammar", "POST", "/ai/grammar-corrector", {"text": "الطلاب ذهب إلى المدرسة"})
        results.append(res)

        # 12. Generate Mock Exam
        res, _ = await test_step("Generate Mock Exam", "GET", "/exams/generate-mock", params={"grade": "bac_scientific", "subject": "physics"})
        results.append(res)

        # 13. Chat Rooms
        res, _ = await test_step("Chat Rooms", "GET", "/chat/rooms")
        results.append(res)

        # 14. Update Profile
        res, _ = await test_step("Update Profile", "PUT", "/user/me", {"full_name": "مستخدم اختبار شامل"})
        results.append(res)

        # 15. User Stats
        res, _ = await test_step("User Stats", "GET", "/user/stats")
        results.append(res)

        # Save all results to a JSON for reporting
        with open("e2e_audit_results.json", "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        
        print("\n✅ E2E Audit completed. Results saved to e2e_audit_results.json")

if __name__ == "__main__":
    asyncio.run(run_comprehensive_audit())
