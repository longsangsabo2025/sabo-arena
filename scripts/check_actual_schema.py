"""
Check actual database schema for privacy and blocks tables
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🔍 Checking Actual Database Schema')
print('=' * 70)

# Check user_privacy_settings columns
print('\n📊 user_privacy_settings columns:')
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'user_privacy_settings'
    ORDER BY ordinal_position
""")
for col, dtype in cur.fetchall():
    print(f'  • {col} ({dtype})')

# Check user_blocks columns
print('\n📊 user_blocks columns:')
cur.execute("""
    SELECT column_name, data_type 
    FROM information_schema.columns 
    WHERE table_name = 'user_blocks'
    ORDER BY ordinal_position
""")
for col, dtype in cur.fetchall():
    print(f'  • {col} ({dtype})')

# Check user_blocks foreign keys
print('\n🔗 user_blocks foreign keys:')
cur.execute("""
    SELECT
        tc.constraint_name, 
        kcu.column_name, 
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name 
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name='user_blocks'
""")
for name, col, ftable, fcol in cur.fetchall():
    print(f'  • {col} → {ftable}.{fcol}')

print('\n' + '=' * 70)
conn.close()
