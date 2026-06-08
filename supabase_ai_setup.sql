-- 1. Create video_summaries table (Cache for Lesson Summaries)
CREATE TABLE IF NOT EXISTS public.video_summaries (
    lesson_id UUID PRIMARY KEY REFERENCES public.lessons(id) ON DELETE CASCADE,
    summary_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. Create ai_exams table (Cache for Generated Quizzes)
CREATE TABLE IF NOT EXISTS public.ai_exams (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE CASCADE,
    exam_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 3. Create ai_usage_logs table
CREATE TABLE IF NOT EXISTS public.ai_usage_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    model_id TEXT NOT NULL,
    feature TEXT,
    prompt_tokens INTEGER DEFAULT 0,
    completion_tokens INTEGER DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,
    duration_ms INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 5. Create ai_recommendations table
CREATE TABLE IF NOT EXISTS public.ai_recommendations ( 
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY, 
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, 
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE, 
    score FLOAT DEFAULT 0, 
    reason TEXT, 
    viewed BOOLEAN DEFAULT FALSE, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL, 
    UNIQUE(user_id, course_id) 
);

-- 6. Create ai_general_cache table for Smart Cache
CREATE TABLE IF NOT EXISTS public.ai_general_cache (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    feature TEXT NOT NULL,
    lesson_id TEXT,
    input_hash TEXT NOT NULL,
    response_content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(feature, lesson_id, input_hash)
);

-- 7. Enable RLS
ALTER TABLE public.video_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_general_cache ENABLE ROW LEVEL SECURITY;

-- 8. Create Policies
CREATE POLICY "Allow authenticated read summaries" ON public.video_summaries FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated insert summaries" ON public.video_summaries FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow authenticated read exams" ON public.ai_exams FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated insert exams" ON public.ai_exams FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users view own logs" ON public.ai_usage_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own logs" ON public.ai_usage_logs FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users view own recommendations" ON public.ai_recommendations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own recommendations" ON public.ai_recommendations FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Allow authenticated read cache" ON public.ai_general_cache FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Allow authenticated insert cache" ON public.ai_general_cache FOR INSERT WITH CHECK (auth.role() = 'authenticated');
