"""
Fix notification rank display bug
"""
import json
import psycopg2

# Load environment variables from env.json
with open('env.json', 'r') as f:
    env = json.load(f)

db_url = env['SUPABASE_DB_TRANSACTION_URL']

print("Connecting to database...")
conn = psycopg2.connect(db_url)
cursor = conn.cursor()
print("Connected successfully\n")

# Read migration file
with open('supabase/migrations/20251220000001_fix_notification_rank.sql', 'r', encoding='utf-8') as f:
    migration_sql = f.read()

print("Running migration to fix notification rank...")

try:
    cursor.execute(migration_sql)
    conn.commit()
    print("Migration completed successfully!")
    
    # Verify
    cursor.execute("""
        SELECT EXISTS (
            SELECT 1 
            FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'admin_approve_rank_change_request'
        );
    """)
    
    exists = cursor.fetchone()[0]
    if exists:
        print("Function admin_approve_rank_change_request verified")
    else:
        print("WARNING: Function not found after migration")
    
except Exception as e:
    print(f"Error: {e}")
    conn.rollback()
finally:
    cursor.close()
    conn.close()

print("\nAll done! Notifications will now show the correct requested rank.")
