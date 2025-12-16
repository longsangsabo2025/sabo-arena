import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
cur = conn.cursor()

# Check user_role enum values
cur.execute("SELECT enumlabel FROM pg_enum WHERE enumtypid = 'user_role'::regtype")
print("user_role enum values:")
for r in cur.fetchall():
    print(f"  - {r[0]}")

# Check skill_level enum values
cur.execute("SELECT enumlabel FROM pg_enum WHERE enumtypid = 'skill_level'::regtype")
print("\nskill_level enum values:")
for r in cur.fetchall():
    print(f"  - {r[0]}")

cur.close()
conn.close()
