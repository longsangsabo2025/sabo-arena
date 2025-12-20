"""
ELON MODE: Check demo users - no fluff, just data
"""
import psycopg2
import json

with open('env.json', 'r') as f:
    env = json.load(f)

conn = psycopg2.connect(env['SUPABASE_DB_TRANSACTION_URL'])
cur = conn.cursor()

print('🚀 ELON MODE: CHECKING DEMO USER POLLUTION\n')
print('=' * 70)

# Get ALL users with patterns
cur.execute("""
    SELECT 
        username,
        full_name,
        current_rank,
        current_elo,
        created_at,
        id
    FROM users 
    WHERE username ILIKE 'test%' 
       OR username ILIKE 'demo%' 
       OR username ILIKE 'sabo%'
    ORDER BY created_at
""")

users = cur.fetchall()

if not users:
    print('\n✅ ZERO demo users. Database is PRISTINE.\n')
    print('This is what efficiency looks like. Ship it.')
    cur.close()
    conn.close()
    exit(0)

print(f'\n🔴 FOUND {len(users)} DEMO/TEST ACCOUNTS:\n')

for i, (username, full_name, rank, elo, created, uid) in enumerate(users, 1):
    print(f'{i}. {username}')
    print(f'   Name: {full_name}')
    print(f'   Rank: {rank or "None"} | ELO: {elo}')
    print(f'   Created: {created.strftime("%Y-%m-%d %H:%M")}')
    print(f'   ID: {uid}')
    
    # Check their activity (tournaments)
    cur.execute('SELECT COUNT(*) FROM tournament_participants WHERE user_id = %s', (uid,))
    tournaments = cur.fetchone()[0]
    
    # Check matches
    cur.execute('''
        SELECT COUNT(*) FROM matches 
        WHERE player1_id = %s OR player2_id = %s
    ''', (uid, uid))
    matches = cur.fetchone()[0]
    
    # Check posts
    cur.execute('SELECT COUNT(*) FROM posts WHERE author_id = %s', (uid,))
    posts = cur.fetchone()[0]
    
    print(f'   Activity: {tournaments} tournaments, {matches} matches, {posts} posts')
    print()

print('=' * 70)
print(f'\n💡 ANALYSIS:')
print(f'   {len(users)} accounts = database bloat')
print(f'   These are TEST artifacts, not production users')
print(f'   Recommendation: DELETE ALL')
print(f'\n📋 Next: Run elon_nuke_demo.py to clean this up\n')

cur.close()
conn.close()
