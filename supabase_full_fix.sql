-- 1. Profiles & Users
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS username TEXT;

-- 2. Wallets & Transactions
CREATE TABLE IF NOT EXISTS public.wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    balance DECIMAL(12, 2) DEFAULT 0.00,
    currency TEXT DEFAULT 'SYP',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID REFERENCES public.wallets(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    type TEXT CHECK (type IN ('deposit', 'withdrawal', 'payment', 'refund')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    reference_id TEXT,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. Courses & Lessons
CREATE TABLE IF NOT EXISTS public.courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    subject TEXT,
    grade_level TEXT,
    price DECIMAL(12, 2) DEFAULT 0.00,
    cover_url TEXT,
    rating DECIMAL(3, 2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    video_url TEXT,
    order_index INTEGER DEFAULT 0,
    duration_seconds INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 4. Chat & Support
CREATE TABLE IF NOT EXISTS public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID REFERENCES public.lessons(id) ON DELETE SET NULL,
    title TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    role TEXT CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 5. FAQs
CREATE TABLE IF NOT EXISTS public.faqs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 6. Fix for Posts relation (PGRST200)
-- Ensure 'posts' has a user_id foreign key that matches auth.users or user_profiles
-- If already exists, just make sure the relation is explicit in the select query.

-- 7. RLS Enablement
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.faqs ENABLE ROW LEVEL SECURITY;

-- 8. Policies
CREATE POLICY "Users can view their own wallet" ON public.wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view their own transactions" ON public.wallet_transactions FOR SELECT USING (
    wallet_id IN (SELECT id FROM public.wallets WHERE user_id = auth.uid())
);
CREATE POLICY "Everyone can view approved courses" ON public.courses FOR SELECT USING (status = 'approved');
CREATE POLICY "Everyone can view lessons" ON public.lessons FOR SELECT USING (true);
CREATE POLICY "Users can manage their chat sessions" ON public.chat_sessions FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can view their chat messages" ON public.chat_messages FOR SELECT USING (
    session_id IN (SELECT id FROM public.chat_sessions WHERE user_id = auth.uid())
);
CREATE POLICY "Everyone can view faqs" ON public.faqs FOR SELECT USING (true);

-- 9. Sample Data
INSERT INTO public.courses (title, description, subject, grade_level, price, cover_url, status) VALUES
('الفيزياء الحديثة', 'شرح مفصل لمنهاج الفيزياء للبكالوريا', 'فيزياء', 'بكالوريا', 50000, 'https://images.unsplash.com/photo-1636466484362-c1335099b12c?q=80&w=400&auto=format&fit=crop', 'approved'),
('الرياضيات - الجزء الأول', 'أساسيات التحليل الهندسي والرياضي', 'رياضيات', 'تاسع', 35000, 'https://images.unsplash.com/photo-1509228468518-180dd48a5791?q=80&w=400&auto=format&fit=crop', 'approved');

-- 10. RPC for Likes
CREATE OR REPLACE FUNCTION public.increment_post_likes(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrement_post_likes(post_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.posts SET likes_count = likes_count - 1 WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
