import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1"
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const MODELS = [
  "mistralai/mistral-7b-instruct:free",
  "meta-llama/llama-3-8b-instruct:free",
  "google/gemini-1.5-flash:free"
]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { feature, lessonId, userPrompt, chatHistory, userMessage, metadata, model: requestedModel } = await req.json()
    const startTime = Date.now()
    const { data: { user } } = await supabaseClient.auth.getUser()

    if (!user) throw new Error("Unauthorized")

    // 1. Rate Limiting (10 requests per minute)
    const { count: recentRequests } = await supabaseClient
      .from('ai_usage_logs')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', user.id)
      .gt('created_at', new Date(Date.now() - 60000).toISOString())

    if (recentRequests && recentRequests >= 10) {
      return new Response(JSON.stringify({ error: "Rate limit exceeded (10 req/min). Please wait." }), {
        status: 429,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 2. Smart Cache
    const inputForHash = JSON.stringify({ feature, lessonId, userPrompt, userMessage, metadata })
    const hashBuffer = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(inputForHash))
    const inputHash = Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padLeft(2, "0")).join("")

    const { data: cachedResponse } = await supabaseClient
      .from('ai_general_cache')
      .select('response_content')
      .eq('feature', feature)
      .eq('lesson_id', lessonId || 'global')
      .eq('input_hash', inputHash)
      .maybeSingle()

    if (cachedResponse) {
      return new Response(JSON.stringify({ content: cachedResponse.response_content, cached: true }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // 3. Prepare AI Request based on feature
    let systemPrompt = "أنت مساعد تعليمي ذكي لمنصة كورسيريا."
    let responseFormat = undefined

    switch (feature) {
      case 'summary':
        systemPrompt = "أنت خبير في تلخيص المحتوى التعليمي. قدم ملخصاً احترافياً بـ Markdown ونقاط واضحة."
        break
      case 'quiz':
        systemPrompt = "ولد اختباراً بصيغة JSON Array يحتوي على أسئلة (question, options, correct_index, explanation)."
        responseFormat = { type: "json_object" }
        break
      case 'similar_quiz':
        systemPrompt = "بناءً على نتائج الاختبار السابق، ولد اختباراً جديداً بنفس مستوى الصعوبة والمواضيع، بصيغة JSON Array."
        responseFormat = { type: "json_object" }
        break
      case 'chat':
        const { data: lesson } = await supabaseClient.from('lessons').select('title, description').eq('id', lessonId).single()
        systemPrompt = `أنت مساعد لدرس "${lesson?.title}". سياق: ${lesson?.description}. كن ودوداً وتعليمياً.`
        break
      case 'recommendation':
        systemPrompt = "بناءً على بيانات الطالب، رشح كورسات بصيغة JSON كائن يحتوي على مصفوفة recommendations."
        responseFormat = { type: "json_object" }
        break
      case 'grading':
        systemPrompt = "قم بتصحيح الإجابة المقالية للطالب بناءً على السؤال المعطى. قدم درجة (0-10) وملاحظات تحسينية دقيقة."
        break
      case 'translation':
        systemPrompt = "ترجم النص التعليمي التالي إلى اللغة العربية بدقة مع الحفاظ على المصطلحات العلمية."
        break
      case 'weakness_analysis':
        systemPrompt = "حلل نتائج اختبارات الطالب وحدد نقاط الضعف بدقة مع اقتراح خطة علاجية."
        break
      case 'flashcards':
        systemPrompt = "ولد بطاقات مراجعة (Flashcards) بصيغة JSON Array تحتوي على (front, back) لمراجعة الدرس."
        responseFormat = { type: "json_object" }
        break
      case 'teacher_assistant':
        systemPrompt = "أنت مساعد خبير للمعلم. قدم إجابات نموذجية، أفكار لتمارين، أو طرق لتبسيط الشرح، واستخدم لغة مهنية."
        break
      case 'learning_style':
        systemPrompt = "حلل شخصية الطالب التعليمية (بصري، سمعي، حركي، إلخ) بناءً على نشاطه واهتماماته. قدم نصائح مخصصة للدراسة."
        break
      case 'class_analytics':
        systemPrompt = "حلل تقدم الفصل الدراسي بشكل كامل. قدم إحصائيات عن المواضيع الصعبة، الطلاب المتميزين، وتوصيات للمعلم."
        break
      case 'expected_questions':
        systemPrompt = "بناءً على المادة العلمية، ولد قائمة بالأسئلة المتوقعة في الامتحان مع إجاباتها النموذجية."
        break
      case 'discussion_summary':
        systemPrompt = "لخص النقاشات الدائرة في المجتمع التعليمي. استخرج أهم النقاط، الأسئلة المتكررة، والحلول المقترحة."
        break
      case 'content_correction':
        systemPrompt = "أنت مدقق لغوي وعلمي. راجع النص وقدم اقتراحات للتحسين من حيث الدقة اللغوية والعلمية."
        break
      case 'group_questions':
        systemPrompt = "ولد أسئلة نقاشية تفاعلية لمجموعة دراسية بناءً على اهتماماتهم المشتركة، بصيغة JSON Array."
        responseFormat = { type: "json_object" }
        break
      case 'task_assignment':
        systemPrompt = "اقترح توزيعاً ذكياً للمهام على أعضاء المجموعة بناءً على مهارات واهتمامات كل عضو."
        break
      case 'study_plan':
        systemPrompt = "أنت خبير تنظيم دراسي. ولد خطة دراسية أسبوعية مخصصة للطالب بناءً على أهدافه ووقت فراغه."
        break
    }

    const messages = [
      { role: "system", content: systemPrompt },
      ...(chatHistory || []),
      { role: "user", content: userMessage || userPrompt }
    ]

    // 4. Call OpenRouter with Fallback Logic
    let aiData = null
    let usedModel = ""
    const openRouterKey = Deno.env.get("OPENROUTER_API_KEY")

    // Priority: 1. Model requested by client, 2. Default MODELS list
    const modelList = requestedModel ? [requestedModel, ...MODELS] : MODELS;

    for (const model of modelList) {
      try {
        const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${openRouterKey}`,
            "Content-Type": "application/json",
            "HTTP-Referer": "https://coursyria.com",
            "X-Title": "Coursyria AI Gateway",
          },
          body: JSON.stringify({
            model: model,
            messages: messages,
            temperature: 0.7,
            response_format: responseFormat,
          }),
        })

        aiData = await response.json()
        if (aiData.choices && aiData.choices[0]) {
          usedModel = model
          break
        }
      } catch (e) {
        console.error(`Model ${model} failed, trying next...`)
      }
    }

    if (!aiData || !aiData.choices) throw new Error("All AI models failed.")

    const content = aiData.choices[0].message.content
    const usage = aiData.usage
    const duration = Date.now() - startTime

    // 5. Save to Cache & Logs (Async)
    supabaseClient.from('ai_general_cache').insert({
      feature,
      lesson_id: lessonId || 'global',
      input_hash: inputHash,
      response_content: content
    }).then()

    supabaseClient.from('ai_usage_logs').insert({
      user_id: user.id,
      model_id: usedModel,
      feature,
      prompt_tokens: usage?.prompt_tokens ?? 0,
      completion_tokens: usage?.completion_tokens ?? 0,
      total_tokens: usage?.total_tokens ?? 0,
      duration_ms: duration,
    }).then()

    return new Response(JSON.stringify({ content, usage, model: usedModel, cached: false }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
