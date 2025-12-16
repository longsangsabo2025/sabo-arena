#!/usr/bin/env python3
import os
import psycopg2
from dotenv import load_dotenv
load_dotenv()

conn = psycopg2.connect(os.getenv('SUPABASE_DB_TRANSACTION_URL'))
cur = conn.cursor()

print("users columns:")
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'users'
    ORDER BY ordinal_position
""")
for col in cur.fetchall():
    print(f'  {col[0]}: {col[1]}')

print("\nuser_profiles columns:")
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'user_profiles'
    ORDER BY ordinal_position
""")
for col in cur.fetchall():
    print(f'  {col[0]}: {col[1]}')

print("\nForeign keys on users:")
cur.execute("""
    SELECT
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
    FROM information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
        AND (tc.table_name = 'users' OR ccu.table_name = 'users')
    LIMIT 10
""")
for row in cur.fetchall():
    print(f'  {row}')

cur.close()
conn.close()
