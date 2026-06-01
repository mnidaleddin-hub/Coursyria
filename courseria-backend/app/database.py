from supabase import create_client, Client
from app.config import get_settings

settings = get_settings()

# عميل Supabase العام (Anon Key) - يُستخدم للعمليات العامة وتطبيق RLS عبر التوكنات
supabase_public: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)

# عميل Supabase للإدارة (Service Role Key) - يتخطى RLS ويُستخدم للمهام الحساسة فقط
supabase_admin: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)

def get_db_admin() -> Client:
    """الحصول على عميل Supabase بصلاحيات الأدمن (يتخطى RLS)"""
    return supabase_admin

def get_db_client_with_token(token: str) -> Client:
    """إنشاء عميل Supabase مضبوط بهيدر Authorization الخاص بالمستخدم لتفعيل RLS"""
    client = create_client(settings.SUPABASE_URL, settings.SUPABASE_KEY)
    client.postgrest.auth(token)
    return client

# إضافة اسم مستعار (Alias) لضمان التوافق مع الكود الذي يستورد هذا الاسم مباشرة
get_supabase_client = get_db_client_with_token

# للإبقاء على التوافق مع الكود القديم (اختياري)
def get_db():
    try:
        yield supabase_public
    finally:
        pass
