from app.database import supabase_admin
try:
    res = supabase_admin.table('phone_verifications').select('*').eq('phone_number', 'trae_test_final@example.com').execute()
    print(f"Data: {res.data}")
except Exception as e:
    print(f"Error: {e}")
