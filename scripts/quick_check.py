import psycopg2
import json
import sys

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🔍 Connecting to database...', flush=True)

cur.execute("""
    SELECT COUNT(*) FROM users 
    WHERE username ILIKE %s OR username ILIKE %s OR username ILIKE %s
""", ('test%', 'demo%', 'sabo%'))

count = cur.fetchone()[0]
print(f'\n🚀 ELON MODE: Found {count} demo/test users polluting the database\n')

if count > 0:
    cur.execute("""
        SELECT username, full_name, created_at::date 
        FROM users 
        WHERE username ILIKE %s OR username ILIKE %s OR username ILIKE %s
        ORDER BY created_at
    """, ('test%', 'demo%', 'sabo%'))
    
    print('List of garbage accounts:')
    for username, fullname, created in cur.fetchall():
        print(f'  • {username} ({fullname}) - {created}')
    
    print(f'\n💡 Recommendation: NUKE THEM ALL\n')

conn.close()
