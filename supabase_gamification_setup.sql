-- 1. Create Achievements Table
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    icon_name TEXT NOT NULL, -- Name of PhosphorIcon
    points_reward INTEGER DEFAULT 0,
    rarity TEXT DEFAULT 'common', -- common, rare, legendary
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 2. Create User Achievements (Junction Table)
CREATE TABLE IF NOT EXISTS public.user_achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES public.achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(user_id, achievement_id)
);

-- 3. Create Stickers Table
CREATE TABLE IF NOT EXISTS public.stickers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    emoji TEXT NOT NULL,
    price INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- 4. Create User Stickers (Junction Table)
CREATE TABLE IF NOT EXISTS public.user_stickers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sticker_id UUID REFERENCES public.stickers(id) ON DELETE CASCADE,
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(user_id, sticker_id)
);

-- 5. Add Performance Indexes
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_user_id ON public.ai_usage_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_logs_created_at ON public.ai_usage_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_cache_created_at ON public.ai_general_cache(created_at);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON public.user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_stickers_user_id ON public.user_stickers(user_id);

-- 6. RLS Policies
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stickers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stickers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read achievements" ON public.achievements FOR SELECT USING (true);
CREATE POLICY "Users view own achievements" ON public.user_achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Allow public read stickers" ON public.stickers FOR SELECT USING (true);
CREATE POLICY "Users view own stickers" ON public.user_stickers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users buy stickers" ON public.user_stickers FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 7. Automatic Streak Function
CREATE OR REPLACE FUNCTION update_user_streak() 
RETURNS TRIGGER AS $$ 
BEGIN 
    UPDATE user_profiles 
    SET current_streak = CASE 
        WHEN last_active_date IS NULL THEN 1
        WHEN (NOW()::DATE - last_active_date::DATE) = 1 THEN current_streak + 1 
        WHEN (NOW()::DATE - last_active_date::DATE) > 1 THEN 1 
        ELSE current_streak 
    END, 
    last_active_date = NOW()::DATE 
    WHERE id = NEW.user_id; 
    RETURN NEW; 
END; 
$$ LANGUAGE plpgsql SECURITY DEFINER; 

-- 8. Streak Trigger
DROP TRIGGER IF EXISTS trigger_update_streak ON public.quiz_results;
CREATE TRIGGER trigger_update_streak 
AFTER INSERT ON public.quiz_results 
FOR EACH ROW 
EXECUTE FUNCTION update_user_streak();

-- 9. Initial Data Seed
INSERT INTO public.stickers (name, emoji, price) VALUES 
('المستكشف', '🚀', 100),
('العبقري', '🧠', 250),
('البطل', '🏆', 500),
('المتحمس', '🔥', 150),
('النجم', '🌟', 300),
('الخريج', '🎓', 1000)
ON CONFLICT DO NOTHING;

INSERT INTO public.achievements (title, description, icon_name, points_reward, rarity) VALUES 
('المتصفح الليلي', 'استخدام الوضع الداكن لمدة 7 أيام متتالية', 'moon', 100, 'rare'),
('الملتزم المثالي', 'تسجيل دخول لمدة 30 يوماً دون انقطاع', 'calendarCheck', 500, 'legendary'),
('قناص المعرفة', 'إكمال 5 دروس في يوم واحد', 'target', 200, 'rare'),
('صديق المجتمع', 'الحصول على 100 إعجاب على منشوراتك', 'usersThree', 150, 'rare')
ON CONFLICT DO NOTHING;
