import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ.get("SUPABASE_URL")
key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    print("Error: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not found in environment")
    exit(1)

supabase = create_client(url, key)

tables_to_check = [
    "users", "courses", "lessons", "user_progress", "posts", "comments", 
    "chat_rooms", "chat_messages", "wallets", "transactions", 
    "user_settings", "promo_codes", "exam_attempts"
]

print("Verifying tables in Supabase...")
results = {}

for table in tables_to_check:
    try:
        # Try to select one row to check if table exists
        supabase.table(table).select("*").limit(1).execute()
        results[table] = "Exists"
    except Exception as e:
        error_msg = str(e)
        if "does not exist" in error_msg.lower() or "not found" in error_msg.lower():
            results[table] = "Missing"
        else:
            results[table] = f"Error: {error_msg}"

for table, status in results.items():
    print(f"- {table}: {status}")
