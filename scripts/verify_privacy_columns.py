#!/usr/bin/env python3
"""
Quick check: Verify actual column names in user_privacy_settings table
"""
import psycopg2
import json
from pathlib import Path

# Load credentials
env_path = Path(__file__).parent.parent / 'env.json'
with open(env_path) as f:
    env = json.load(f)

# Connect to database (using transaction pooler port 6543)
conn = psycopg2.connect(
    host=env['SUPABASE_DB_HOST'],
    port=6543,
    database='postgres',
    user=env['SUPABASE_DB_USER'],
    password=env['SUPABASE_DB_PASSWORD']
)

cur = conn.cursor()

print("=" * 80)
print("USER_PRIVACY_SETTINGS TABLE SCHEMA")
print("=" * 80)

# Get column names and types
cur.execute("""
    SELECT column_name, data_type, is_nullable
    FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'user_privacy_settings'
    ORDER BY ordinal_position;
""")

columns = cur.fetchall()
if columns:
    print("\nColumns:")
    for col_name, data_type, nullable in columns:
        print(f"  - {col_name:30} {data_type:15} {'NULL' if nullable == 'YES' else 'NOT NULL'}")
else:
    print("\n❌ Table does NOT exist!")

# Check if table has any data
cur.execute("SELECT COUNT(*) FROM user_privacy_settings;")
count = cur.fetchone()[0]
print(f"\nRow count: {count}")

# Check users count
cur.execute("SELECT COUNT(*) FROM users;")
user_count = cur.fetchone()[0]
print(f"Users count: {user_count}")

print("\n" + "=" * 80)

# If table exists but has wrong columns, we need to know
if columns and count == 0:
    print("\n⚠️  Table exists but has 0 rows - existing users need default settings!")
    print("\nTo fix: Run create_default_privacy_settings.py")

cur.close()
conn.close()
