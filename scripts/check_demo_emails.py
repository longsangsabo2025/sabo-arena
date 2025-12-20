"""
Check emails containing 'demo'
"""
import psycopg2
import json

env = json.load(open('env.json'))
conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🔍 Scanning email column for "demo" pattern...\n')

cur.execute("""
    SELECT 
        id,
        username,
        email,
        phone,
        rank,
        elo_rating,
        created_at
    FROM users 
    WHERE email ILIKE '%demo%'
    ORDER BY created_at
""")

results = cur.fetchall()

if not results:
    print('✅ No emails containing "demo" found.\n')
    conn.close()
    exit(0)

print(f'🔴 FOUND {len(results)} users with "demo" in email:\n')

for uid, username, email, phone, rank, elo, created in results:
    print(f'👤 {username}')
    print(f'   Email: {email}')
    print(f'   Phone: {phone or "None"}')
    print(f'   Rank: {rank or "None"} | ELO: {elo}')
    print(f'   Created: {created.strftime("%Y-%m-%d %H:%M")}')
    print(f'   ID: {uid}')
    print()

print(f'📊 Total: {len(results)} users\n')

conn.close()
