from fastapi import APIRouter, HTTPException, Depends, status, Body, UploadFile, File
from app.dependencies import get_current_user, get_supabase_client
from app.config import get_settings
from typing import List, Optional
import datetime
import httpx
import json

router = APIRouter()
settings = get_settings()

async def call_openrouter(messages: list, model: str = None, json_mode: bool = False):
    """Helper to call OpenRouter API"""
    if not settings.OPENROUTER_API_KEY:
        # Fallback to mock if no API key is provided (useful for local dev without key)
        return {
            "choices": [{"message": {"content": "Mock AI response: Please set OPENROUTER_API_KEY for real responses."}}],
            "usage": {"total_tokens": 0}
        }

    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://courseria.com", # Required by OpenRouter
        "X-Title": "Courseria AI"
    }
    
    payload = {
        "model": model or settings.DEFAULT_AI_MODEL,
        "messages": messages
    }
    
    if json_mode:
        payload["response_format"] = {"type": "json_object"}

    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            response = await client.post(settings.OPENROUTER_URL, headers=headers, json=payload)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"OpenRouter Error: {e}")
            raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")

@router.post("/chat")
async def ai_chat(
    message: str = Body(..., embed=True),
    context: Optional[str] = Body(None, embed=True),
    user=Depends(get_current_user)
):
    """إرسال سؤال نصي إلى الذكاء الاصطناعي"""
    messages = [
        {"role": "system", "content": "أنت مساعد تعليمي ذكي لمنصة كورسيريا، ساعد الطلاب في سوريا بأسلوب ودود وواضح."},
        {"role": "user", "content": f"Context: {context}\nQuestion: {message}" if context else message}
    ]
    
    response = await call_openrouter(messages)
    content = response["choices"][0]["message"]["content"]
    usage = response.get("usage", {})
    
    return {
        "reply": content,
        "usage": usage
    }

@router.post("/summarize")
async def ai_summarize(
    content: str = Body(..., embed=True),
    user=Depends(get_current_user)
):
    """طلب توليد ملخص درس تلقائي"""
    messages = [
        {"role": "system", "content": "أنت خبير في تلخيص المحتوى التعليمي. قدم ملخصاً احترافياً باللغة العربية بـ Markdown ونقاط واضحة."},
        {"role": "user", "content": f"Summarize this educational content:\n{content}"}
    ]
    
    response = await call_openrouter(messages)
    summary = response["choices"][0]["message"]["content"]
    
    return {
        "summary": summary,
        "key_points": [] # Could be extracted from content if needed
    }

@router.post("/explain-like-im-5")
async def ai_explain_simple(
    content: str = Body(..., embed=True),
    user=Depends(get_current_user)
):
    """تبسيط مفهوم معقد (ELI5)"""
    messages = [
        {"role": "system", "content": "أنت خبير في تبسيط المفاهيم المعقدة للأطفال أو المبتدئين. اشرح النص التالي بأسلوب بسيط جداً ومشوق."},
        {"role": "user", "content": content}
    ]
    
    response = await call_openrouter(messages)
    explanation = response["choices"][0]["message"]["content"]
    
    return {
        "explanation": explanation
    }

@router.post("/flashcards")
async def ai_generate_flashcards(
    content: str = Body(..., embed=True),
    user=Depends(get_current_user)
):
    """طلب توليد بطاقات تعليمية من نص معين"""
    messages = [
        {"role": "system", "content": "ولد 5 بطاقات تعليمية (سؤال وجواب) من النص التالي بصيغة JSON. format: {\"flashcards\": [{\"question\": \"...\", \"answer\": \"...\"}]}"},
        {"role": "user", "content": content}
    ]
    
    response = await call_openrouter(messages, json_mode=True)
    try:
        data = json.loads(response["choices"][0]["message"]["content"])
        return data
    except:
        return {"flashcards": [], "error": "Failed to parse AI response"}

@router.post("/grammar-corrector")
async def ai_correct_grammar(
    text: str = Body(..., embed=True),
    user=Depends(get_current_user)
):
    """تصحيح الأخطاء اللغوية والنحوية"""
    messages = [
        {"role": "system", "content": "أنت خبير لغوي في اللغة العربية. قم بتصحيح الأخطاء الإملائية والنحوية في النص التالي وأعد النص المصحح فقط."},
        {"role": "user", "content": text}
    ]
    
    response = await call_openrouter(messages)
    corrected_text = response["choices"][0]["message"]["content"]
    
    return {
        "original": text,
        "corrected": corrected_text
    }

@router.post("/generate-quiz")
async def ai_generate_quiz(
    content: str = Body(..., embed=True),
    user=Depends(get_current_user)
):
    """توليد اختبار من نص الدرس"""
    messages = [
        {"role": "system", "content": "ولد اختباراً من 5 أسئلة من النص التالي بصيغة JSON. format: {\"questions\": [{\"text\": \"...\", \"options\": [\"...\"], \"correct\": 0}]}"},
        {"role": "user", "content": content}
    ]
    
    response = await call_openrouter(messages, json_mode=True)
    try:
        data = json.loads(response["choices"][0]["message"]["content"])
        return data
    except:
        return {"questions": [], "error": "Failed to parse AI response"}
