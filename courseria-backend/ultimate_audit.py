import httpx
import asyncio
import time
import json
import uuid
from datetime import datetime

BASE_URL = "https://coursyria-api.onrender.com"
BACKDOOR_CODE = "@1258998521@"

async def run_ultimate_audit():
    results = []
    headers = {}
    context = {}

    async with httpx.AsyncClient(timeout=60.0) as client:
        print(f"🕵️ Starting ULTIMATE Quality Audit on {BASE_URL}...")

        async def log_step(name, method, path, data=None, params=None, current_headers=None):
            step_headers = current_headers if current_headers is not None else headers
            start = time.time()
            try:
                if method == "GET":
                    resp = await client.get(f"{BASE_URL}{path}", headers=step_headers, params=params)
                elif method == "POST":
                    resp = await client.post(f"{BASE_URL}{path}", headers=step_headers, json=data)
                elif method == "PUT":
                    resp = await client.put(f"{BASE_URL}{path}", headers=step_headers, json=data)
                
                duration = (time.time() - start) * 1000
                
                try:
                    res_body = resp.json()
                except:
                    res_body = resp.text

                success = resp.status_code in [200, 201, 204]
                
                # Logic check: even if 200, is the content logical?
                logic_issue = None
                if success and method == "GET" and path == "/courses" and not isinstance(res_body, list):
                    logic_issue = "Expected list of courses but got something else"
                
                step_result = {
                    "name": name,
                    "endpoint": f"{method} {path}",
                    "status": resp.status_code,
                    "duration": duration,
                    "success": success and not logic_issue,
                    "response_summary": str(res_body)[:100],
                    "logic_issue": logic_issue
                }
                print(f"[{resp.status_code}] {name} - {duration:.2f}ms")
                return step_result, resp
            except Exception as e:
                duration = (time.time() - start) * 1000
                print(f"[ERR] {name} - {e}")
                return {
                    "name": name,
                    "endpoint": f"{method} {path}",
                    "status": 500,
                    "duration": duration,
                    "success": False,
                    "response_summary": str(e),
                    "logic_issue": "Exception occurred"
                }, None

        # --- I. AUTHENTICATION & PROFILE ---
        # 1.1 Send OTP
        res, _ = await log_step("1.1 Send Email OTP", "POST", "/auth/send-email-otp", {"email": f"tester_{int(time.time())}@example.com"})
        results.append(res)

        # 1.2 Verify OTP (using backdoor for guaranteed access)
        res, resp = await log_step("1.2 Verify OTP (Backdoor)", "POST", "/auth/verify-email-otp", {
            "contact": BACKDOOR_CODE,
            "otp": BACKDOOR_CODE
        })
        results.append(res)
        if res["success"]:
            token = resp.json()["access_token"]
            headers["Authorization"] = f"Bearer {token}"
            context["user_id"] = resp.json()["user"]["id"]

        # 2.1 Get Profile
        res, _ = await log_step("2.1 Get Profile", "GET", "/user/me")
        results.append(res)

        # 2.2 Update Profile
        res, _ = await log_step("2.2 Update Name", "PUT", "/user/me", {"full_name": "اختبار شامل"})
        results.append(res)

        # --- II. COURSES & LESSONS ---
        # 3.1 Fetch Courses
        res, resp = await log_step("3.1 Fetch All Courses", "GET", "/courses")
        results.append(res)
        if res["success"] and resp.json():
            context["course_id"] = resp.json()[0]["id"]

        # 3.2 Course Details
        if "course_id" in context:
            res, resp = await log_step("3.2 Course Details", "GET", f"/courses/{context['course_id']}")
            results.append(res)
            if res["success"] and resp.json().get("lessons"):
                context["lesson_id"] = resp.json()["lessons"][0]["id"]

        # --- III. COMMUNITY ---
        # 4.1 Create Post
        res, resp = await log_step("4.1 Create Community Post", "POST", "/community/posts", {"content": "اختبار شامل للمجتمع"})
        results.append(res)
        if res["success"]:
            context["post_id"] = resp.json()["id"]

        # 4.3 Fetch Posts
        res, _ = await log_step("4.3 Fetch Posts List", "GET", "/community/posts")
        results.append(res)

        # 4.4 Add Comment
        if "post_id" in context:
            res, _ = await log_step("4.4 Add Comment", "POST", f"/community/posts/{context['post_id']}/comments", {"content": "هذا تعليق اختبار"})
            results.append(res)

        # --- IV. WALLET ---
        # 5.1 Wallet Balance
        res, _ = await log_step("5.1 Check Wallet Balance", "GET", "/wallet/balance")
        results.append(res)

        # 5.2 Use Promo Code (Fake)
        res, _ = await log_step("5.2 Use Promo Code (Fake)", "POST", "/wallet/use-promo-code", {"code": "TEST99"})
        results.append(res)

        # --- V. AI SERVICES (REAL RESPONSES) ---
        # 6.1 AI Chat
        res, _ = await log_step("6.1 AI Chat (Newton 3rd Law)", "POST", "/ai/chat", {"message": "ما هو قانون نيوتن الثالث؟"})
        results.append(res)

        # 6.2 AI Summarize
        res, _ = await log_step("6.2 AI Summarize (Cloud Computing)", "POST", "/ai/summarize", {"content": "الحوسبة السحابية هي توفر موارد أنظمة الحاسوب عند الطلب، وخاصة تخزين البيانات وقوة الحوسبة، دون إدارة نشطة مباشرة من قبل المستخدم." * 10})
        results.append(res)

        # 6.3 AI Quiz
        res, _ = await log_step("6.3 AI Generate Quiz", "POST", "/ai/generate-quiz", {"content": "مقدمة في البرمجة"})
        results.append(res)

        # 6.4 AI Explain LI5
        res, _ = await log_step("6.4 AI Explain LI5", "POST", "/ai/explain-like-im-5", {"content": "معادلات ماكسويل"})
        results.append(res)

        # 6.5 AI Flashcards
        res, _ = await log_step("6.5 AI Flashcards", "POST", "/ai/flashcards", {"content": "أهم 5 مفاهيم في الفيزياء"})
        results.append(res)

        # 6.6 AI Grammar
        res, _ = await log_step("6.6 AI Grammar Correction", "POST", "/ai/grammar-corrector", {"text": "الطلاب يذاكر جيداً"})
        results.append(res)

        # --- VI. EXAMS & CHAT ---
        # 7.1 Generate Mock
        res, _ = await log_step("7.1 Generate Mock Exam", "GET", "/exams/generate-mock", params={"grade": "bac_scientific", "subject": "physics"})
        results.append(res)

        # 8.1 Get Chat Rooms
        res, _ = await log_step("8.1 Get Chat Rooms", "GET", "/chat/rooms")
        results.append(res)

        # --- VII. SYSTEM & EDGE CASES ---
        # 9.1 User Stats
        res, _ = await log_step("9.1 Get User Stats", "GET", "/user/stats")
        results.append(res)

        # 9.3 Health Check
        res, _ = await log_step("9.3 System Health Check", "GET", "/health")
        results.append(res)

        # 10.1 404 Case
        res, _ = await log_step("10.1 Non-existent Course (404)", "GET", "/courses/99999999-9999-9999-9999-999999999999")
        results.append(res)

        # 10.2 Empty Content (400 or handle)
        res, _ = await log_step("10.2 Empty Post Content (Bad Request)", "POST", "/community/posts", {"content": ""})
        results.append(res)

        # 10.3 Unauthorized (401)
        res, _ = await log_step("10.3 Access without Token (401)", "GET", "/user/me", current_headers={})
        results.append(res)

        # Finalize
        with open("ultimate_audit_results.json", "w", encoding="utf-8") as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print("\n🏁 Ultimate Audit Finished.")

if __name__ == "__main__":
    asyncio.run(run_ultimate_audit())
