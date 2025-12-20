"""
Quick check actual database columns
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🔍 ACTUAL DATABASE COLUMNS')
print('=' * 70)

# Check user_privacy_settings columns
print('\n📊 user_privacy_settings:')
cur.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'user_privacy_settings'
    ORDER BY ordinal_position
""")
cols = [row[0] for row in cur.fetchall()]
for col in cols:
    print(f'  • {col}')

# Check user_blocks columns
print('\n📊 user_blocks:')
cur.execute("""
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name = 'user_blocks'
    ORDER BY ordinal_position
""")
cols = [row[0] for row in cur.fetchall()]
for col in cols:
    print(f'  • {col}')

# Check if there are any rows in user_privacy_settings
print('\n📊 Row counts:')
cur.execute("SELECT COUNT(*) FROM user_privacy_settings")
print(f'  user_privacy_settings: {cur.fetchone()[0]} rows')

cur.execute("SELECT COUNT(*) FROM user_blocks")
print(f'  user_blocks: {cur.fetchone()[0]} rows')

conn.close()
print('\n' + '=' * 70)
